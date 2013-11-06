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

TaskboardController = ($scope, $rootScope, $routeParams, $q, rs, $data) ->
    # Global Scope Variables
    $rootScope.pageSection = 'dashboard'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        ["Taskboard", null]
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
            $scope.stats = {
                totalPoints: totalPoints
                completedPoints: completedPoints
                percentageCompletedPoints: ((completedPoints*100) / totalPoints).toFixed(1)
                totalUss: milestoneStats.total_userstories
                compledUss: milestoneStats.completed_userstories
                totalTasks: milestoneStats.total_tasks
                completedTasks: milestoneStats.completed_tasks
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

    $scope.openCreateTaskForm = (us) ->
        options =
            status: $scope.project.default_task_status
            project: projectId
            milestone: sprintId

        if us != undefined
            options.user_story = us.id

        $rootScope.$broadcast("task-form:open", "create", options)

    $scope.$on "task-form:create", (ctx, model) ->
        $scope.tasks.push(model)
        formatUserStoryTasks()
        calculateStats()

    $scope.$on "stats:reload", ->
        calculateStats()

    $scope.$on "sortable:changed", ->
        for usId, statuses of $scope.usTasks
            for statusId, tasks of statuses
                for task in tasks
                    task.user_story = parseInt(usId, 10)
                    task.status = parseInt(statusId, 10)
                    if task.isModified()
                        task.save().then ->
                            calculateStats()

        for statusId, tasks of $scope.unassignedTasks
            for task in tasks
                task.user_story = null
                task.status = parseInt(statusId, 10)
                if task.isModified()
                    task.save().then ->
                        calculateStats()


TaskboardTaskFormController = ($scope, $rootScope, $gmOverlay, $gmFlash, rs) ->
    $scope.type = "create"
    $scope.formOpened = false

    $scope.submit = ->
        promise = rs.createTask($scope.form)

        promise.then (model) ->
            $rootScope.$broadcast("task-form:create", model)
            $scope.overlay.close()
            $scope.formOpened = false
            $gmFlash.info("The task has been saved", false)

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.type == "create"
            $scope.form = {}
        else
            $scope.form.revert()

    $scope.$on "task-form:open", (ctx, type, form={}) ->
        $scope.type = type
        $scope.form = form
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

    $scope.$on "task-form:close", ->
        $scope.formOpened = false

TaskboardTaskController = ($scope, $rootScope, $q) ->
    $scope.updateTaskAssignation = (task, id) ->
        task.assigned_to = id || null
        task.save()

    $scope.getTaskColorStyle = (task) ->
        user = $rootScope.constants.users[task.assigned_to]
        if user != undefined
            return {"border-color": $rootScope.constants.users[task.assigned_to].color or '#FFF5D8'}
        return '#FFF5D8'


module = angular.module("greenmine.controllers.taskboard", [])
module.controller("TaskboardTaskController", ['$scope', '$rootScope', '$q', TaskboardTaskController])
module.controller("TaskboardController", ['$scope', '$rootScope', '$routeParams', '$q', 'resource', '$data', TaskboardController])
module.controller("TaskboardTaskFormController", ['$scope', '$rootScope', '$gmOverlay', '$gmFlash', 'resource', TaskboardTaskFormController])
