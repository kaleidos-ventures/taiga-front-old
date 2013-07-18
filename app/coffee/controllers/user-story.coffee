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


UserStoryViewController = ($scope, $location, $rootScope, $routeParams, $q, rs) ->
    $rootScope.pageSection = 'user-stories'
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    userStoryId = $routeParams.userstoryid

    promise = $q.all [
        rs.getUsStatuses(projectId),
        rs.getUsers(projectId),
        rs.getUserStory(projectId, userStoryId)
    ]

    promise.then (results) ->
        usStatuses = results[0]
        users = results[1]
        userStory = results[2]

        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)
        _.each(usStatuses, (item) -> $rootScope.constants.status[item.id] = item)

        $scope.userStory = userStory
        $scope.form = _.extend({}, $scope.userStory._attrs)

        $rootScope.pageBreadcrumb = ["Project", "User stories", "#" + userStory.ref]
        $rootScope.constants.statusList = _.sortBy(usStatuses, "order")
        $rootScope.constants.usersList = _.sortBy(users, "id")

    $scope.userStory = {}
    $scope.form = {}

    $scope.submit = ->
        console.log "SUBMIT"
        for key, value of $scope.form
            $scope.userStory[key] = value

        promise = $scope.userStory.save()
        promise.then ->
            console.log "ASDASD", arguments

    $scope.removeTask = (userStory) ->
        task.remove().then ->
            $location.url("/project/#{projectId}/")

module = angular.module("greenmine.controllers.user-story", [])
module.controller("UserStoryViewController", ['$scope', '$location', '$rootScope', '$routeParams', '$q', 'resource', UserStoryViewController])
