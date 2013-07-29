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
    $rootScope.pageBreadcrumb = ["Project", "Taskboard"]

    $scope.projectId = $routeParams.pid
    $scope.sprintId = $routeParams.sid
    $scope.statuses = []

    projectId = $routeParams.pid
    sprintId = $routeParams.sid || 1

    formatUserStoryTasks = ->
        $scope.usTasks = {}
        $scope.unassignedTasks = {}

        for us in $scope.userstoriesList
            console.log us
            $scope.usTasks[us.id] = {}

            for status in $scope.statusesList
                $scope.usTasks[us.id][status.id] = []

        for status in $scope.statusesList
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
        pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope.constants.pointsByOrder, $scope.roles)

        totalTasks = $scope.tasks.length
        totalUss = $scope.userstoriesList.length
        totalPoints = 0

        completedPoints = 0
        compledUss = 0
        completedTasks = 0

        _.each $scope.userstoriesList, (us) ->
            totalPoints += pointIdToOrder(us.points)

        _.each $scope.usTasks, (statuses, usId) ->
            hasOpenTasks = false
            hasTasks = false

            _.each statuses, (tasks, statusId) ->
                hasTasks = true
                if $scope.statuses[statusId].is_closed
                    completedTasks += tasks.length
                else if tasks.length > 0
                    hasOpenTasks = true

            if hasOpenTasks is false and hasTasks is true
                compledUss += 1
                us = $scope.userstories[usId]
                points = pointIdToOrder(us.points)
                completedPoints += points

        $scope.stats =
            totalPoints: totalPoints
            completedPoints: completedPoints.toFixed(0)
            percentageCompletedPoints: ((completedPoints*100) / totalPoints).toFixed(1)
            totalUss: totalUss
            compledUss: compledUss.toFixed(0)
            totalTasks: totalTasks
            completedTasks: completedTasks


    loadTasks = ->
        rs.getTasks($scope.projectId, $scope.sprintId).then (tasks) ->
            $scope.tasks = tasks
            formatUserStoryTasks()
            calculateStats()

    $data.loadProject($scope).then ->
        $data.loadCommonConstants($scope).then ->
            promise = $q.all [$data.loadUserStoryPoints($scope)
                              $data.loadTaskboardData($scope)]
            promise.then(loadTasks)

    $scope.openCreateTaskForm = (us) ->
        options =
            status: $scope.statusesList[0].id
            project: projectId

        if us != undefined
            options.user_story = us.id

        $rootScope.$broadcast("task-form:open", "create", options)

    $scope.$on "task-form:create", (ctx, model) ->
        $scope.tasks.push(model)
        formatUserStoryTasks()
        calculateStats()

    $scope.$on "sortable:changed", ->
        for usId, statuses of $scope.usTasks
            for statusId, tasks of statuses
                for task in tasks
                    task.user_story = parseInt(usId, 10)
                    task.status = parseInt(statusId, 10)
                    task.save() if task.isModified()

        for statusId, tasks of $scope.unassignedTasks
            for task in tasks
                task.user_story = null
                task.status = parseInt(statusId, 10)
                task.save() if task.isModified()

        calculateStats()


TaskboardTaskFormController = ($scope, $rootScope, $gmOverlay, rs) ->
    $scope.type = "create"
    $scope.formOpened = false

    $scope.submit = ->
        rs.createTask($scope.form).then (model) ->
            $rootScope.$broadcast("task-form:create", model)
            $scope.overlay.close()
            $scope.formOpened = false

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

TaskboardTaskController = ($scope, $q) ->
    $scope.updateTaskAssignation = (task, id) ->
        task.assigned_to = id ? id : null
        task.save()



module = angular.module("greenmine.controllers.taskboard", [])
module.controller("TaskboardTaskController", ['$scope', '$q', TaskboardTaskController])
module.controller("TaskboardController", ['$scope', '$rootScope', '$routeParams', '$q', 'resource', '$data', TaskboardController])
module.controller("TaskboardTaskFormController", ['$scope', '$rootScope', '$gmOverlay', 'resource', TaskboardTaskFormController])
