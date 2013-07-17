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


TasksViewController = ($scope, $location, $rootScope, $routeParams, $q, rs) ->
    $rootScope.pageSection = 'tasks'
    $rootScope.pageBreadcrumb = ["Project", "Tasks", "#" + $routeParams.taskid]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    taskId = $routeParams.taskid

    $scope.task = {}
    $scope.form = {}
    $scope.updateFormOpened = false

    loadAttachments = ->
        rs.getTaskAttachments(projectId, taskId).then (attachments) ->
            $scope.attachments = attachments

    loadTask = ->
        rs.getTask(projectId, taskId).then (task) ->
            $scope.task = task
            $scope.form = _.extend({}, $scope.task._attrs)

    # Initial load
    loadAttachments()
    loadTask()

    promise = $q.all [
        rs.getTaskStatuses(projectId),
        rs.getUsers(projectId),
    ]

    promise.then (results) ->
        taskStatuses = results[0]
        users = results[1]

        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)
        _.each(taskStatuses, (item) -> $rootScope.constants.status[item.id] = item)

        $rootScope.constants.statusList = _.sortBy(taskStatuses, "order")
        $rootScope.constants.usersList = _.sortBy(users, "id")


    $scope.isSameAs = (property, id) ->
        return ($scope.task[property] == parseInt(id, 10))

    $scope.submit = ->
        rs.uploadTaskAttachment(projectId, taskId, $scope.attachment)

        for key, value of $scope.form
            $scope.task[key] = value

        $scope.task.save().then (task) ->
            loadTask()
            loadAttachments()

    $scope.removeAttachment = (attachment) ->
        console.log "removeAttachment", attachment
        $scope.attachments = _.reject($scope.attachments, {"id": attachment.id})
        attachment.remove()

    $scope.removeTask = (task) ->
        milestone = task.milestone
        task.remove().then ->
            $location.url("/project/#{projectId}/dashboard/#{milestone}/")


module = angular.module("greenmine.controllers.tasks", [])
module.controller("TasksViewController", ['$scope', '$location', '$rootScope', '$routeParams', '$q', 'resource', TasksViewController])