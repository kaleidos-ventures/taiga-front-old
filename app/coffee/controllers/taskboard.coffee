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

TaskboardController = ($scope, $rootScope, $routeParams, $q, rs, $data, $modal, $i18next) ->
    # Global Scope Variables
    $rootScope.pageTitle = $i18next.t('common.taskboard')
    $rootScope.pageSection = 'dashboard'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t('common.taskboard'), null]
    ]

    $scope.projectId = $routeParams.pid
    $scope.sprintId = $routeParams.sid

    projectId = $routeParams.pid
    sprintId = $routeParams.sid || 1

    calculateTotalPoints = (us) ->
        total = 0

        for role in $scope.constants.computableRolesList
            pointId = us.points[role.id]
            total += $scope.constants.points[pointId].value

        return total

    formatUserStoryTasks = ->
        $scope.usTasks = {}
        $scope.unassignedTasks = {}

        for us in $scope.userstoriesList
            $scope.usTasks[us.id] = {}

            for status in $scope.constants.taskStatusesList
                $scope.usTasks[us.id][status.id] = []

        for status in $scope.constants.taskStatusesList
            $scope.unassignedTasks[status.id] = []

        for task in $scope.tasks
            if task.user_story == null
                $scope.unassignedTasks[task.status].push(task)
            else
                # why? because a django-filters sucks
                if $scope.usTasks[task.user_story]?
                    $scope.usTasks[task.user_story][task.status].push(task)

        return

    calculateStats = ->
        rs.getMilestoneStats($scope.sprintId).then (milestoneStats) ->
            totalPoints = _.reduce(milestoneStats.total_points, (x, y) -> x + y) || 0
            completedPoints = _.reduce(milestoneStats.completed_points, (x, y) -> x + y) || 0
            percentageCompletedPoints = ((completedPoints*100) / totalPoints).toFixed(1)
            $scope.stats = {
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
            }
            $scope.milestoneStats = milestoneStats

    loadTasks = ->
        rs.getTasks($scope.projectId, $scope.sprintId).then (tasks) ->
            $scope.tasks = tasks
            formatUserStoryTasks()
            calculateStats()

    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            promise = $data.loadTaskboardData($scope)
            promise.then(loadTasks)

    $scope.saveUsPoints = (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        us._moving = true
        promise = us.save()
        promise.then ->
            us._moving = false
            calculateStats()
            $scope.$broadcast("points:changed")

        promise.then null, (data, status) ->
            us._moving = false
            us.revert()

    $scope.saveUsStatus = (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) ->
            data._moving = false


    $scope.openCreateTaskForm = (us) ->
        options =
            status: $scope.project.default_task_status
            project: projectId
            milestone: sprintId

        if us != undefined
            options.user_story = us.id

        promise = $modal.open("task-form", {'task': options, 'type': 'create'})
        promise.then (us) ->
            $scope.tasks.push(us)
            formatUserStoryTasks()
            calculateStats()

    $scope.openEditTaskForm = (us, task) ->
        promise = $modal.open("task-form", {'task': task, 'type': 'edit'})
        promise.then ->
            formatUserStoryTasks()
            calculateStats()

    $scope.$on "stats:reload", ->
        calculateStats()

    $scope.$on "sortable:changed", gm.utils.safeDebounced $scope, 100, ->
        saveTask = (task) ->
            if not task.isModified()
                return

            task._moving = true

            promise = task.save()
            promise.then (task) ->
                task._moving = false
                calculateStats()

            promise.then null, (error) ->
                task.revert()
                task._moving = false
                loadTasks()

        for usId, statuses of $scope.usTasks
            for statusId, tasks of statuses
                for task in tasks
                    task.user_story = parseInt(usId, 10)
                    task.status = parseInt(statusId, 10)
                    saveTask(task)

        for statusId, tasks of $scope.unassignedTasks
            for task in tasks
                task.user_story = null
                task.status = parseInt(statusId, 10)
                saveTask(task)

    return


TaskboardTaskModalController = ($scope, $rootScope, $gmOverlay, $gmFlash, rs, $i18next) ->
    $scope.type = "create"
    $scope.formOpened = false

    # Load data
    $scope.defered = null
    $scope.context = null

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    openModal = ->
        loadProjectTags()
        $scope.form = $scope.context.task
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

    closeModal = ->
        $scope.formOpened = false

    @.initialize = (dfr, ctx) ->
        $scope.defered = dfr
        $scope.context = ctx
        openModal()

    @.delete = ->
        closeModal()
        $scope.form = form
        $scope.formOpened = true

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        if $scope.form.id?
            promise = $scope.form.save(false)
        else
            promise = rs.createTask($scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            $scope.$emit("spinner:stop")
            closeModal()
            $scope.overlay.close()
            $scope.defered.resolve($scope.form)
            $gmFlash.info($i18next.t('taskboard.user-story-saved'))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.form.id?
            $scope.form.revert()
        else
            $scope.form = {}

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

    return


TaskboardTaskController = ($scope, $rootScope, $q, $location) ->
    $scope.updateTaskAssignation = (task, id) ->
        task.assigned_to = id || null
        task.save()

    $scope.openTask = (projectId, taskId)->
        $location.url("/project/#{projectId}/tasks/#{taskId}")

    return


module = angular.module("greenmine.controllers.taskboard", [])
module.controller("TaskboardTaskController", ['$scope', '$rootScope', '$q', "$location", TaskboardTaskController])
module.controller("TaskboardController", ['$scope', '$rootScope', '$routeParams', '$q', 'resource', '$data', '$modal', "$i18next", TaskboardController])
module.controller("TaskboardTaskModalController", ['$scope', '$rootScope', '$gmOverlay', '$gmFlash', 'resource', "$i18next", TaskboardTaskModalController])
