DataServiceProvider = ($rootScope, $q, rs) ->
    service = {}

    service.loadProject = ($scope) ->
        promise = rs.getProject($rootScope.projectId).then (project) ->
            $rootScope.project = project
            $rootScope.$broadcast("project:loaded", project)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[0] = project.name

            $rootScope.pageBreadcrumb = breadcrumb

        return promise

    service.loadUserStoryPoints = ($scope) ->
        promise = rs.getUsPoints($rootScope.projectId)
        promise = promise.then (points) ->
            $rootScope.constants.points = {}
            $rootScope.constants.pointsByOrder = {}
            $rootScope.constants.pointsList = _.sortBy(points, "order")

            for item in points
                $rootScope.constants.points[item.id] = item
                $rootScope.constants.pointsByOrder[item.order] = item

            $rootScope.$broadcast("points:loaded", points)
            return points

        return promise

    service.loadUnassignedUserStories = ($scope) ->
        promise = rs.getUnassignedUserStories($rootScope.projectId)
        promise = promise.then (unassingedUs) ->
            projectId = parseInt($rootScope.projectId, 10)

            $scope.unassingedUs = _.filter(unassingedUs, {"project": projectId, milestone: null})
            $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order")
            $rootScope.$broadcast("userstories:loaded")
            return $scope.unassingedUs

        return promise

    service.loadIssueConstants = ($scope) ->
        promise = $q.all [
            rs.getIssueTypes($rootScope.projectId),
            rs.getIssueStatuses($rootScope.projectId),
        ]

        promise = promise.then (results) ->
            [types, statuses] = results

            _.each(types, (item) -> $rootScope.constants.type[item.id] = item)
            _.each(statuses, (item) -> $rootScope.constants.status[item.id] = item)

            $rootScope.constants.typeList = _.sortBy(types, "order")
            $rootScope.constants.statusList = _.sortBy(types, "order")
            return results

        return promise

    service.loadCommonConstants = ($scope) ->
        promise = $q.all [
            rs.getSeverities($rootScope.projectId),
            rs.getPriorities($rootScope.projectId),
            rs.getUsers($rootScope.projectId),
            rs.getRoles($rootScope.projectId),
        ]

        promise = promise.then (results) ->
            [severities, priorities, users, roles] = results

            $rootScope.constants.severityList = _.sortBy(severities, "order")
            $rootScope.constants.priorityList = _.sortBy(priorities, "order")
            $rootScope.constants.usersList = _.sortBy(users, "id")

            _.each(severities, (item) -> $rootScope.constants.severity[item.id] = item)
            _.each(priorities, (item) -> $rootScope.constants.priority[item.id] = item)
            _.each(users, (item) -> $rootScope.constants.users[item.id] = item)

            $scope.roles = roles

            $rootScope.$broadcast("roles:loaded", roles)
            $rootScope.$broadcast("users:loaded", users)

            return results

        return promise
    return service

module = angular.module("greenmine.controllers.common", [])
module.factory("$data", ["$rootScope", "$q", "resource", DataServiceProvider])
