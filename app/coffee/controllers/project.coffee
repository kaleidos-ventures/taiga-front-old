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
    $rootScope.pageBreadcrumb = [
        ["Greenmine", $rootScope.urls.projectsUrl()],
        ["Dashboard", null]
    ]
    $rootScope.projectId = null

    rs.getProjects().then (projects) ->
        $scope.projects = projects


ProjectAdminController = ($scope, $rootScope, $routeParams, $data, $gmFlash, $model,
                          $confirm) ->
    $rootScope.pageSection = 'admin'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        ["Project Admin", null]
    ]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    # This attach "project" to $scope
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope)

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

    $scope.$on "membership:load-project", (ctx) ->
        $data.loadProject($scope)
        $data.loadUsersAndRoles($scope)


MembershipFormController = ($scope, $rootScope, rs) ->
    $scope.formOpened = false

    $scope.toggleForm = ->
        if $scope.formOpened
            $scope.closeForm()
        else
            $scope.openForm()

    $scope.openForm = ->
        $scope.membership = {project: $rootScope.projectId}
        $scope.noMemberUsersList = _.filter($scope.constants.usersList, (user) ->
            return _.indexOf($scope.project.members, user.id) == -1
        )
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.submit = ->
        promise = rs.createMembership($scope.membership)

        promise.then (data) ->
            $rootScope.$broadcast("membership:load-project")
            $scope.closeForm()

        promise.then null, (data) ->
            $scope.checksleyErrors = data


MembershipsController = ($scope, $rootScope, $model, $confirm) ->
    $scope.deleteMember = (member) ->
        promise = $confirm.confirm("Are you sure?")
        promise.then () ->
            $model.make_model('memberships',member).remove().then () ->
                $rootScope.$broadcast("membership:load-project")

    $scope.updateMemberRole = (member, roleId) ->
        memberModel = $model.make_model('memberships',member)
        memberModel.role = roleId
        memberModel.save().then (data) ->
            $rootScope.$broadcast("membership:load-project")


module = angular.module("greenmine.controllers.project", [])
module.controller("ProjectListController", ['$scope', '$rootScope', 'resource',
                                            ProjectListController])
module.controller("ProjectAdminController", ["$scope", "$rootScope", "$routeParams",
                                             "$data", "$gmFlash", "$model", "$confirm",
                                             ProjectAdminController])
module.controller("MembershipFormController", ["$scope", "$rootScope", 'resource',
                                               MembershipFormController])
module.controller("MembershipsController", ["$scope", "$rootScope", "$model", "$confirm",
                                            MembershipsController])
