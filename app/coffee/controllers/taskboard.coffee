# Copyright 2013 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class TaskboardController extends TaigaBaseController
    @.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource',
                 '$data', '$modal', "$model", "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @routeParams, @q, @rs, @data, @modal, @model, @i18next, @favico) ->
        super(scope)

    initialize: ->
        @favico.reset()
        # Global Scope Variables
        @rootScope.pageTitle = @i18next.t('common.taskboard')
        @rootScope.pageSection = 'dashboard'
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t('common.taskboard'), null]
        ]

        @rs.resolve(pslug: @routeParams.pslug, mlref: @routeParams.sslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.sprintSlug = @routeParams.sid
            @rootScope.sprintId = data.milestone

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    promise = @data.loadTaskboardData(@scope)
                    promise.then(@loadTasks)

        @scope.$on "stats:reload", =>
            @calculateStats()

    formatUserStoryTasks: ->
        @scope.usTasks = {}
        @scope.unassignedTasks = {}

        for us in @scope.userstoriesList
            @scope.usTasks[us.id] = {}

            for status in @scope.constants.taskStatusesList
                @scope.usTasks[us.id][status.id] = []

        for status in @scope.constants.taskStatusesList
            @scope.unassignedTasks[status.id] = []

        for task in @scope.tasks
            if task.user_story == null
                @scope.unassignedTasks[task.status].push(task)
            else
                # why? because a django-filters sucks
                if @scope.usTasks[task.user_story]?
                    @scope.usTasks[task.user_story][task.status].push(task)

        return

    calculateStats: ->
        @rs.getMilestoneStats(@scope.sprintId).then (milestoneStats) =>
            totalPoints = _.reduce(milestoneStats.total_points, (x, y) -> x + y) || 0
            completedPoints = _.reduce(milestoneStats.completed_points, (x, y) -> x + y) || 0
            percentageCompletedPoints = ((completedPoints*100) / totalPoints).toFixed(1)
            @scope.stats = {
                totalPoints: totalPoints
                completedPoints: completedPoints
                remainingPoints: totalPoints - completedPoints
                percentageCompletedPoints: if totalPoints == 0 then 0 else percentageCompletedPoints
                totalUss: milestoneStats.total_userstories
                compledUss: milestoneStats.completed_userstories
                remainingUss: milestoneStats.completed_userstories - milestoneStats.completed_userstories
                totalTasks: milestoneStats.total_tasks
                completedTasks: milestoneStats.completed_tasks
                remainingTasks: milestoneStats.total_tasks - milestoneStats.completed_tasks
                iocaineDoses: milestoneStats.iocaine_doses
            }
            @scope.milestoneStats = milestoneStats

    loadTasks: ->
        @rs.getTasks(@scope.projectId, @scope.sprintId).then (tasks) =>
            @scope.tasks = tasks
            @formatUserStoryTasks()
            @calculateStats()

    saveUsPoints: (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        us._moving = true
        promise = us.save()
        promise.then =>
            us._moving = false
            @calculateStats()
            @scope.$broadcast("points:changed")

        promise.then null, (data, status) =>
            us._moving = false
            us.revert()

    saveUsStatus: (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) =>
            data._moving = false

    openBulkTasksForm: (us) ->
        promise = @modal.open("bulk-tasks-form", {us: us})
        promise.then (tasks) =>
            _.each tasks, (task) =>
                newTask = @model.make_model("tasks", task)
                @scope.tasks.push(newTask)

            @formatUserStoryTasks()
            @calculateStats()

    openCreateTaskForm: (us) ->
        options =
            status: @scope.project.default_task_status
            project: @scope.projectId
            milestone: @scope.sprintId

        if us != undefined
            options.user_story = us.id

        promise = @modal.open("task-form", {'task': options, 'type': 'create'})
        promise.then (task) =>
            newTask = @model.make_model("tasks", task)
            @scope.tasks.push(newTask)
            @formatUserStoryTasks()
            @calculateStats()

    openEditTaskForm: (us, task) ->
        promise = @modal.open("task-form", {'task': task, 'type': 'edit'})
        promise.then =>
            @formatUserStoryTasks()
            @calculateStats()

    sortableOnAdd: (task, index, sortableScope) ->
        if sortableScope.us?
            task.user_story = sortableScope.us.id
        else
            task.user_story = null
        task.status = sortableScope.status.id

        task._moving = true
        task.save().then =>
            if sortableScope.us?
                @scope.usTasks[sortableScope.us.id][sortableScope.status.id].splice(index, 0, task)
                sortableScope.us.refresh()
            else
                @scope.unassignedTasks[sortableScope.status.id].splice(index, 0, task)
            task._moving = false

    sortableOnRemove: (task, sortableScope) ->
        if sortableScope.us?
            _.remove(@scope.usTasks[sortableScope.us.id][sortableScope.status.id], task)
        else
            _.remove(@scope.unassignedTasks[sortableScope.status.id], task)


class TaskboardTaskModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', '$gmFlash', 'resource',
                 '$i18next']
    constructor: (@scope, @rootScope, @gmOverlay, @gmFlash, @rs, @i18next) ->
        super(scope)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @scope.type = "create"
        @scope.formOpened = false
        @scope.bulkTasksFormOpened = false

        # Load data
        @scope.defered = null
        @scope.context = null

        @scope.$on "select2:changed", (ctx, value) =>
            @scope.form.tags = value

        @scope.assignedToSelectOptions = {
            formatResult: @assignedToSelectOptionsShowMember
            formatSelection: @assignedToSelectOptionsShowMember
        }

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @scope.projectTags = data

    openModal: ->
        @loadProjectTags()
        @scope.form = @scope.context.task
        @scope.formOpened = true

        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        @scope.overlay = @gmOverlay()
        @scope.overlay.open().then =>
            @scope.formOpened = false

    closeModal: ->
        @scope.formOpened = false

    start: (dfr, ctx) ->
        @scope.defered = dfr
        @scope.context = ctx
        @openModal()

    delete: ->
        @closeModal()
        @scope.form = form
        @scope.formOpened = true

    # Debounced Method (see debounceMethods method)
    submit: =>
        if @scope.form.id?
            promise = @scope.form.save(false)
        else
            promise = @rs.createTask(@scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @scope.overlay.close()
            @scope.form.id = data.id
            @scope.form.ref = data.ref
            @scope.defered.resolve(@scope.form)
            @gmFlash.info(@i18next.t('taskboard.user-story-saved'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    close: ->
        @scope.formOpened = false
        @scope.overlay.close()

        if @scope.form.id?
            @scope.form.revert()
        else
            @scope.form = {}

    assignedToSelectOptionsShowMember: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: make me more beautiful and elegant
            return "<span style=\"color: black; padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
         return "<span\">#{option.text}</span>"


class TaskboardBulkTasksModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash',
                 '$i18next']
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next) ->
        super(scope)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @scope.bulkTasksFormOpened = false

        # Load data
        @scope.defered = null
        @scope.context = null

    openModal: ->
        @scope.bulkTasksFormOpened = true
        @scope.$broadcast("checksley:reset")

        @scope.overlay = @gmOverlay()
        @scope.overlay.open().then =>
            @scope.bulkTasksFormOpened = false

    closeModal: ->
        @scope.bulkTasksFormOpened = false

    start: (dfr, ctx) ->
        @scope.defered = dfr
        @scope.context = ctx
        @openModal()

    delete: ->
        @closeModal()
        @scope.form = form
        @scope.bulkTasksFormOpened = true

    # Debounced Method (see debounceMethods method)
    submit: =>
        promise = @rs.createBulkTasks(@scope.projectId, @scope.context.us.id, @scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @scope.overlay.close()
            @scope.defered.resolve(data.data)
            @gmFlash.info(@i18next.t('taskboard.bulk-tasks-created', { count: data.data.length }))
            @scope.form = {}

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    close: ->
        @scope.bulkTasksFormOpened = false
        @scope.overlay.close()
        @scope.form = {}


class TaskboardTaskController extends TaigaBaseController
    @.$inject = ['$scope', '$location']

    constructor: (@scope, @location) ->
        super(scope)

    updateTaskAssignation: (task, id) ->
        task.assigned_to = id || null
        task._moving = true
        promise = task.save()

        promise.then (task) =>
            task._moving = false

        promise.then null, =>
            task.revert()
            task._moving = false

    openTask: (projectSlug, taskRef) ->
        @location.url("/project/#{projectSlug}/tasks/#{taskRef}")


module = angular.module("taiga.controllers.taskboard", [])
module.controller("TaskboardController", TaskboardController)
module.controller("TaskboardTaskModalController", TaskboardTaskModalController)
module.controller('TaskboardBulkTasksModalController', TaskboardBulkTasksModalController)
module.controller("TaskboardTaskController", TaskboardTaskController)
