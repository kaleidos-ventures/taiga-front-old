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

TaskboardController = ($scope, $rootScope, $routeParams, $q, rs) ->
    # Global Scope Variables
    $rootScope.pageSection = 'dashboard'
    $rootScope.pageBreadcrumb = ["Project", "Taskboard"]
    $rootScope.projectId = $routeParams.pid
    $scope.sprintId = $routeParams.sid
    $scope.statuses = []

    projectId = $routeParams.pid
    sprintId = $routeParams.sid || 1

    formatUserStoryTasks = ->
        $scope.usTasks = {}

        _.each $scope.userstories, (us) ->
            $scope.usTasks[us.id] = {}
            _.each $scope.statuses, (status) ->
                $scope.usTasks[us.id][status.id] = []

        _.each $scope.tasks, (task) ->
            # why? because a django-filters sucks
            if $scope.usTasks[task.user_story]?
                $scope.usTasks[task.user_story][task.status].push(task)

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope.constants.points)

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

    $q.all([
        rs.getTaskStatuses(projectId),
        rs.getMilestone(projectId, sprintId)
        rs.getUsPoints(projectId),
        rs.getTasks(projectId, sprintId),
        rs.getUsers(projectId),
    ]).then((results) ->
        statuses = results[0]
        milestone = results[1]
        points = results[2]
        tasks = results[3]
        users = results[4]

        userstories = milestone.user_stories

        $rootScope.constants.usersList = _.sortBy(users, "id")

        $scope.statusesList = _.sortBy(statuses, 'id')
        $scope.userstoriesList = _.sortBy(userstories, 'id')

        $scope.tasks = tasks
        $scope.userstories = {}
        $scope.statuses = {}
        $scope.milestone = milestone

        _.each(statuses, (status) -> $scope.statuses[status.id] = status)
        _.each(userstories, (us) -> $scope.userstories[us.id] = us)
        _.each(points, (item) -> $rootScope.constants.points[item.id] = item)
        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)

        ## HACK: must be deleted on the near future
        #$scope.tasks = _.filter tasks, (task) ->
        #    return (task.milestone == sprintId && task.project == projectId)

        formatUserStoryTasks()
        calculateStats()
        initializeEmptyForm()
    )

    initializeEmptyForm = ->
        $scope.form = {"status": $scope.statusesList[0].id}

    $scope.submitTask = ->
        form = _.extend({tags:[]}, $scope.form, {"user_story": this.us.id})

        rs.createTask(projectId, form).then (model) ->
            $scope.tasks.push(model)

            formatUserStoryTasks()
            calculateStats()
            initializeEmptyForm()

        # Notify to all modal directives
        # for close all opened modals.
        $scope.$broadcast("modals:close")

    $scope.$on "sortable:changed", ->
        _.each $scope.usTasks, (statuses, usId) ->
            _.each statuses, (tasks, statusId) ->
                _.each tasks, (task) ->
                    task.user_story = parseInt(usId, 10)
                    task.status = parseInt(statusId, 10)

                    task.save() if task.isModified()

        calculateStats()


TaskboardTaskController = ($scope, $q) ->
    $scope.updateTaskAssignation = (task, id) ->
        task.assigned_to = id ? id : null
        task.save()



module = angular.module("greenmine.controllers.taskboard", [])
module.controller("TaskboardTaskController", ['$scope', '$q', TaskboardTaskController])
module.controller("TaskboardController", ['$scope', '$rootScope', '$routeParams', '$q', 'resource', TaskboardController])
