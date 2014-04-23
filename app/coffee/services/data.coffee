# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class DataService extends TaigaBaseService
    @.$inject = ["$rootScope", "$q", "resource"]

    constructor: (@rootScope, @q, @rs) ->
        super()

    loadPermissions: () ->
        promise = @rs.getPermissions().then (permissions) =>
            @rootScope.constants.permissionsList = permissions
            @rootScope.constants.permissionsGroups = permissions

            groups = {}
            for permission in permissions
                resource = permission.codename.replace(/^.*_/,"")
                if groups[resource]?
                    groups[resource].push(permission)
                else
                    groups[resource] = [permission]

            @rootScope.constants.permissionsGroups = groups

        return promise

    loadProjectStats: ($scope) ->
        promise = @rs.getProjectStats($scope.projectId).then (projectStats) =>
            $scope.projectStats = projectStats
            @rootScope.$broadcast("project_stats:loaded", projectStats)

        return promise

    loadProject: ($scope) ->
        promise = @rs.getProject($scope.projectId).then (project) =>
            $scope.project = project
            @rootScope.$broadcast("project:loaded", project)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            breadcrumb[0] = [project.name, @rootScope.urls.backlogUrl(project.slug)]
            @rootScope.pageBreadcrumb = breadcrumb

            # USs
            for item in project.points
                $scope.constants.points[item.id] = item
                $scope.constants.pointsByOrder[item.order] = item

            $scope.constants.pointsList = _.sortBy(project.points, "order")
            @rootScope.$broadcast("points:loaded", project.points)

            # Us statuses
            _.each(project.us_statuses, (status) -> $scope.constants.usStatuses[status.id] = status)
            $scope.constants.usStatusesList = _.sortBy(project.us_statuses, 'id')

            # Tasks statuses
            _.each(project.task_statuses, (item) -> $scope.constants.taskStatuses[item.id] = item)
            $scope.constants.taskStatusesList = _.sortBy(project.task_statuses, "order")

            # Issue statuses
            _.each(project.issue_types, (item) -> $scope.constants.types[item.id] = item)
            $scope.constants.typesList = _.sortBy(project.types, "order")
            _.each(project.severities, (item) -> $scope.constants.severities[item.id] = item)
            $scope.constants.severitiesList = _.sortBy(project.severities, "order")
            _.each(project.priorities, (item) -> $scope.constants.priorities[item.id] = item)
            $scope.constants.prioritiesList = _.sortBy(project.priorities, "order")
            _.each(project.issue_types, (item) -> $scope.constants.issueTypes[item.id] = item)
            $scope.constants.issueTypesList = _.sortBy(project.issue_types, "order")
            _.each(project.issue_statuses, (item) -> $scope.constants.issueStatuses[item.id] = item)
            $scope.constants.issueStatusesList = _.sortBy(project.issue_statuses, "order")

        return promise

    loadTaskboardData: ($scope) ->
        promise = @q.all [
            @rs.getTasks($scope.projectId, $scope.sprintId),
            @rs.getMilestone($scope.projectId, $scope.sprintId),
        ]

        promise = promise.then (results) ->
            [tasks, milestone] = results
            $scope.milestone = milestone

            userstories = milestone.user_stories

            $scope.userstories = {}
            _.each(userstories, (us) -> $scope.userstories[us.id] = us)
            $scope.userstoriesList = userstories
            $scope.$emit("stats:reload")
            return results
        return promise

    loadUnassignedUserStories: ($scope) ->
        promise = @rs.getUnassignedUserStories(@rootScope.projectId)
        promise = promise.then (unassignedUs) =>
            projectId = parseInt(@rootScope.projectId, 10)

            $scope.unassignedUs = _.filter(unassignedUs, {"project": projectId, milestone: null})
            $scope.unassignedUs = _.sortBy($scope.unassignedUs, "order")
            @rootScope.$broadcast("userstories:loaded")
            return $scope.unassignedUs
        return promise

    loadUserStories: ($scope) ->
        promise = @rs.getUserStories(@rootScope.projectId)
        promise = promise.then (uss) =>
            $scope.userstories = _.sortBy(uss, "order")
            @rootScope.$broadcast("userstories:loaded")
            return $scope.userstories
        return promise

    # NOTE: This method depends on getProject
    loadUsersAndRoles: ($scope) ->
        promise = @q.all [
            @rs.getUsers($scope.project.id),
            @rs.getRoles($scope.project.id),
        ]

        promise = promise.then (results) =>
            [users, roles] = results

            $scope.constants.usersList = _.sortBy(users, "id")
            $scope.constants.rolesList = roles

            _.each(users, (item) -> $scope.constants.users[item.id] = item)

            @rootScope.$broadcast("roles:loaded", roles)
            @rootScope.$broadcast("users:loaded", users)

            availableRoles = _($scope.project.memberships).map("role").uniq().value()

            $scope.constants.computableRolesList = _(roles).filter("computable")
                                                           .filter((x) -> _.contains(availableRoles, x.id))
                                                           .value()
            return results
        return promise

    loadSiteInfo: ($scope) ->
        $scope.site = {}

        defered = @q.defer()
        promise = @rs.getSiteInfo()
        promise.then (data) ->
            $scope.site = _.merge($scope.site, data)
            defered.resolve($scope.site)

        promise.then null, ->
            defered.reject()

        return defered.promise

module = angular.module("taiga.services.data", ['taiga.services.resource'])
module.service("$data", DataService)
