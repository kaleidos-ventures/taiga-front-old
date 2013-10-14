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


UserStoryViewController = ($scope, $location, $rootScope, $routeParams, $q, rs, $data) ->
    $rootScope.pageSection = 'user-stories'
    $rootScope.pageBreadcrumb = ["", "User stories", ""]
    $scope.projectId = parseInt($routeParams.pid, 10)

    projectId = $scope.projectId
    userStoryId = $routeParams.userstoryid

    $scope.userStory = {}
    $scope.form = {'points':{}}
    $scope.totalPoints = 0
    $scope.points = {}

    loadUserStory = ->
        rs.getUserStory(projectId, userStoryId).then (userStory) ->
            $scope.userStory = userStory
            $scope.form = _.clone($scope.userStory._attrs, true)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[2] = "##{userStory.ref}"

            $rootScope.pageBreadcrumb = breadcrumb

            pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.pointsByOrder, $scope.roles)
            $scope.totalPoints = pointIdToOrder(userStory.points)

            for roleId, pointsOrder of userStory.points
                $scope.points[roleId] = $scope.constants.pointsByOrder[pointsOrder].name

            #console.log "************** points *****************"
            #for point in $scope.constants.pointsList
            #    console.log "point:", point._attrs

            #console.log "************** roles *****************"
            #for role in $scope.roles
            #    console.log "role:", role._attrs


    # Load initial data
    $data.loadProject($scope)
    $data.loadUsersAndRoles($scope)

    # Initial load
    loadUserStory()

    $scope.submit = ->
        $rootScope.$broadcast("flash:new", true, "La user story se ha guardado!")
        for key, value of $scope.form
            $scope.userStory[key] = value

        $scope.userStory.save().then (userStory)->
            loadUserStory()

    $scope.removeUserStory = (userStory) ->
        userStory.remove().then ->
            $location.url("/project/#{projectId}/backlog")

module = angular.module("greenmine.controllers.user-story", [])
module.controller("UserStoryViewController", ['$scope', '$location', '$rootScope', '$routeParams', '$q', 'resource', "$data", UserStoryViewController])

