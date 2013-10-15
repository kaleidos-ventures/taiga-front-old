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

SearchController = ($scope, $rootScope, $routeParams, $data, rs) ->
    $rootScope.pageSection = 'search'
    $rootScope.projectId = parseInt($routeParams.pid, 10)
    $rootScope.pageBreadcrumb = ["", "Backlog"]

    $data.loadProject($scope)

    $scope.resultTypeMap = {
        userstory: "User Story"
        task: "Task"
        issue: "Issue"
    }

    $scope.translateResultType = (type) ->
        if $scope.resultTypeMap[type] == undefined
            return type
        return $scope.resultTypeMap[type]

    $scope.isTypeActive = (type) ->
        return type == $scope.activeType

    $scope.setActiveType = (type) ->
        $scope.activeType = type

    rs.search($rootScope.projectId, $routeParams.term).then (results) ->
        $scope.results = results
        $scope.resultTypes = _.reject(_.keys($scope.results), (x) -> x == "count")

        $scope.activeType = null
        maxItemsCounter = 0

        for type in $scope.resultTypes
            if $scope.results[type].length > maxItemsCounter
                $scope.activeType = type
                maxItemsCounter = $scope.results[type].length


module = angular.module("greenmine.controllers.search", [])
module.controller("SearchController", ["$scope", "$rootScope", "$routeParams", "$data", "resource", SearchController])
