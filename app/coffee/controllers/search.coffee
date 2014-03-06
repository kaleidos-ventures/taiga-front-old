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

SearchController = ($scope, $rootScope, $routeParams, $data, rs, $i18next) ->
    $rootScope.pageTitle = $i18next.t("common.search")
    $rootScope.pageSection = 'search'

    $rootScope.pageBreadcrumb = [
        ["", ""]
        [$i18next.t("common.search"), null]
    ]

    $scope.term = $routeParams.term

    $scope.resultTypeMap = {
        userstories: "User Stories"
        tasks: "Tasks"
        issues: "Issues"
        wikipages: "Wiki Pages"
    }

    $scope.translateResultType = (type) ->
        if $scope.resultTypeMap[type] == undefined
            return type
        return $scope.resultTypeMap[type]

    $scope.translateTypeUrl = (type, projectSlug, item) ->
        return switch type
            when "userstories" then $rootScope.urls.userStoryUrl(projectSlug, item.ref)
            when "tasks" then $rootScope.urls.tasksUrl(projectSlug, item.ref)
            when "issues" then $rootScope.urls.issuesUrl(projectSlug, item.ref)
            when "wikipages" then $rootScope.urls.wikiUrl(projectSlug, item.slug)

    $scope.translateTypeTitle = (type, item) ->
        return switch type
            when "userstories" then item.subject
            when "tasks" then item.subject
            when "issues" then item.subject
            when "wikipages" then item.slug

    $scope.translateTypeDescription = (type, item) ->
        return switch type
            when "userstories" then item.description
            when "tasks" then item.description
            when "issues" then item.description
            when "wikipages" then item.content

    $scope.isTypeActive = (type) ->
        return type == $scope.activeType

    $scope.setActiveType = (type) ->
        $scope.activeType = type


    rs.resolve(pslug: $routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $data.loadProject($scope)

        rs.search($rootScope.projectId, $routeParams.term, false).then (results) ->
            $scope.results = results
            $scope.resultTypes = _.reject(_.keys($scope.results), (x) -> x == "count")

            $scope.activeType = null
            maxItemsCounter = 0

            for type in $scope.resultTypes
                if $scope.results[type].length > maxItemsCounter
                    $scope.activeType = type
                    maxItemsCounter = $scope.results[type].length

    return


module = angular.module("taiga.controllers.search", [])
module.controller("SearchController", ["$scope", "$rootScope", "$routeParams", "$data", "resource", "$i18next", SearchController])
