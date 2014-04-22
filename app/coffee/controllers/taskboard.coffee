# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class TaskboardController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource',
                 '$data', '$modal', "$model", "$i18next", "$favico",
                 "selectOptions"]
    constructor: (@scope, @rootScope, @routeParams, @q, @rs, @data, @modal,
                  @model, @i18next, @favico, @selectOptions) ->
        super(scope, rootScope, favico)

    section: 'dashboard'
    getTitle: ->
        @i18next.t('common.taskboard')

    initialize: ->
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
                @scope.unassignedTasks[task.status]?.push(task)
            else
                # why? because a django-filters sucks
                if @scope.usTasks[task.user_story]?
                    @scope.usTasks[task.user_story][task.status]?.push(task)

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
                remainingUss: milestoneStats.total_userstories - milestoneStats.completed_userstories
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

        promise.then null, (data, status) ->
            us._moving = false
            us.revert()

    saveUsStatus: (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) ->
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

        return promise

    openEditTaskForm: (us, task) ->
        promise = @modal.open("task-form", {'task': task, 'type': 'edit'})
        promise.then =>
            @formatUserStoryTasks()
            @calculateStats()

        return promise

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
                 '$i18next', "selectOptions"]
    constructor: (@scope, @rootScope, @gmOverlay, @gmFlash, @rs, @i18next, @selectOptions) ->
        super(scope)

    initialize: ->
        @scope.type = "create"
        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @selectOptions.colorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
        }

        super()

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    openModal: ->
        @loadProjectTags()
        @scope.form = @scope.context.task
        @scope.formOpened = true

        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        @gmOverlay.open().then =>
            @scope.formOpened = false

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
            @gmOverlay.close()
            @scope.form.id = data.id
            @scope.form.ref = data.ref
            @scope.defered.resolve(@scope.form)
            @gmFlash.info(@i18next.t('taskboard.user-story-saved'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise

class TaskboardBulkTasksModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash',
                 '$i18next']
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next) ->
        super(scope)

    openModal: ->
        @scope.form = {}
        @scope.formOpened = true
        @scope.$broadcast("checksley:reset")

        @gmOverlay.open().then =>
            @scope.formOpened = false


    # Debounced Method (see debounceMethods method)
    submit: =>
        promise = @rs.createBulkTasks(@scope.projectId, @scope.context.us.id, @scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @gmOverlay.close()
            @scope.defered.resolve(data.data)
            @gmFlash.info(@i18next.t('taskboard.bulk-tasks-created', { count: data.data.length }))
            @scope.form = {}

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise

class TaskboardTaskController extends TaigaBaseController
    @.$inject = ['$scope', '$location']

    constructor: (@scope, @location) ->
        super(scope)

    updateTaskAssignation: (task, id) ->
        task.assigned_to = id || null
        task._moving = true
        promise = task.save()

        promise.then (task) ->
            task._moving = false

        promise.then null, ->
            task.revert()
            task._moving = false

        return promise

    openTask: (projectSlug, taskRef) ->
        @location.url("/project/#{projectSlug}/tasks/#{taskRef}")


moduleDeps = ['taiga.services.resource', 'taiga.services.data', 'gmModal',
              "taiga.services.model", "i18next", "favico", 'gmOverlay',
              'gmFlash', "taiga.services.selectOptions"]
module = angular.module("taiga.controllers.taskboard", moduleDeps)
module.controller("TaskboardController", TaskboardController)
module.controller("TaskboardTaskModalController", TaskboardTaskModalController)
module.controller('TaskboardBulkTasksModalController', TaskboardBulkTasksModalController)
module.controller("TaskboardTaskController", TaskboardTaskController)
