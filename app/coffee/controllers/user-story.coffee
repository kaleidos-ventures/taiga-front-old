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
    $rootScope.pageBreadcrumb = ["", "User stories", ""]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    userStoryId = $routeParams.userstoryid

    $scope.userStory = {}
    $scope.form = {}

    loadUserStory = ->
        rs.getUserStory(projectId, userStoryId).then (userStory) ->
            $scope.userStory = userStory
            $scope.form = _.extend({}, $scope.userStory._attrs)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[2] = "##{userStory.ref}"

            $rootScope.pageBreadcrumb = breadcrumb

    # Load initial data
    rs.getProject($rootScope.projectId).then (project) ->
        $scope.project = project
        $rootScope.$broadcast("project:loaded", project)

        breadcrumb = _.clone($rootScope.pageBreadcrumb)
        breadcrumb[0] = project.name
        $rootScope.pageBreadcrumb = breadcrumb

    # Initial load
    promise = $q.all [
        rs.getUsStatuses(projectId),
        rs.getUsers(projectId),
    ]

    promise.then (results) ->
        usStatuses = results[0]
        users = results[1]

        _.each(users, (item) -> $scope.constants.users[item.id] = item)
        _.each(usStatuses, (item) -> $scope.constants.status[item.id] = item)

        $scope.constants.statusList = _.sortBy(usStatuses, "order")
        $scope.constants.usersList = _.sortBy(users, "id")
        loadUserStory()

    $scope.submit = ->
        for key, value of $scope.form
            $scope.userStory[key] = value

        $scope.userStory.save().then (userStory)->
            loadUserStory()

    $scope.removeUserStory = (userStory) ->
        userStory.remove().then ->
            $location.url("/project/#{projectId}/backlog")

module = angular.module("greenmine.controllers.user-story", [])
module.controller("UserStoryViewController", ['$scope', '$location', '$rootScope', '$routeParams', '$q', 'resource', UserStoryViewController])

