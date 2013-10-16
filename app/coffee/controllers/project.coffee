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

ProjectListController = ($scope, $rootScope, rs) ->
    $rootScope.pageSection = 'projects'
    $rootScope.pageBreadcrumb = ["Greenmine", "Dashboard"]
    $rootScope.projectId = null

    rs.getProjects().then (projects) ->
        $scope.projects = projects


ProjectAdminController = ($scope, $rootScope, $routeParams, $data, $gmFlash, $model, $confirm, rs) ->
    $rootScope.pageSection = 'admin'
    $rootScope.pageBreadcrumb = ["", "Project Admin"]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    # This attach "project" to $scope
    $data.loadProject($scope)

    $scope.submit = ->
        promise = $scope.project.save()
        promise.then (data) ->
            $gmFlash.info("Project saved successful!")

        promise.then null, (data) ->
            console.error data
            $scope.checksleyErrors = data

    $scope.deleteMilestone = (milestone) ->
        promise = $confirm.confirm("Are you sure?")
        promise.then () ->
            $model.make_model('milestones', milestone).remove().then () ->
                $data.loadProject($scope)


module = angular.module("greenmine.controllers.project", [])
module.controller("ProjectListController", ['$scope', '$rootScope', 'resource', ProjectListController])
module.controller("ProjectAdminController", ["$scope", "$rootScope", "$routeParams", "$data",
                                             "$gmFlash", "$model", "$confirm", "resource", ProjectAdminController])
