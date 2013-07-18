DataServiceProvider = ($rootScope, $q, rs) ->
    service = {}

    service.loadProject = ($scope) ->
        promise = rs.getProject($scope.projectId).then (project) ->
            $scope.project = project
            $rootScope.$broadcast("project:loaded", project)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[0] = project.name
            $rootScope.pageBreadcrumb = breadcrumb

        return promise

    service.loadUserStoryPoints = ($scope) ->
        promise = rs.getUsPoints($scope.projectId)
        promise = promise.then (points) ->
            $scope.constants.points = {}
            $scope.constants.pointsByOrder = {}
            $scope.constants.pointsList = _.sortBy(points, "order")

            for item in points
                $scope.constants.points[item.id] = item
                $scope.constants.pointsByOrder[item.order] = item

            $rootScope.$broadcast("points:loaded", points)
            return points

        return promise

    service.loadTaskboardData = ($scope) ->
        promise = $q.all [
            rs.getTasks($scope.projectId, $scope.sprintId),
            rs.getTaskStatuses($scope.projectId),
            rs.getMilestone($scope.projectId, $scope.sprintId),
        ]

        promise = promise.then (results) ->
            [tasks, statuses, milestone] = results

            userstories = milestone.user_stories

            $scope.statuses = {}
            $scope.userstories = {}

            $scope.statusesList = _.sortBy(statuses, 'id')
            $scope.userstoriesList = _.sortBy(userstories, 'id')

            _.each(statuses, (status) -> $scope.statuses[status.id] = status)
            _.each(userstories, (us) -> $scope.userstories[us.id] = us)

            return results

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
            rs.getIssueTypes($scope.projectId),
            rs.getIssueStatuses($scope.projectId),
        ]

        promise = promise.then (results) ->
            [types, statuses] = results

            _.each(types, (item) -> $scope.constants.type[item.id] = item)
            _.each(statuses, (item) -> $scope.constants.status[item.id] = item)

            $scope.constants.typeList = _.sortBy(types, "order")
            $scope.constants.statusList = _.sortBy(statuses, "order")
            return results

        return promise

    service.loadCommonConstants = ($scope) ->
        promise = $q.all [
            rs.getSeverities($scope.projectId),
            rs.getPriorities($scope.projectId),
            rs.getUsers($scope.projectId),
            rs.getRoles($scope.projectId),
        ]

        promise = promise.then (results) ->
            [severities, priorities, users, roles] = results

            $scope.constants.severityList = _.sortBy(severities, "order")
            $scope.constants.priorityList = _.sortBy(priorities, "order")
            $scope.constants.usersList = _.sortBy(users, "id")

            _.each(severities, (item) -> $scope.constants.severity[item.id] = item)
            _.each(priorities, (item) -> $scope.constants.priority[item.id] = item)
            _.each(users, (item) -> $scope.constants.users[item.id] = item)

            $scope.roles = roles

            $rootScope.$broadcast("roles:loaded", roles)
            $rootScope.$broadcast("users:loaded", users)

            return results

        return promise
    return service

module = angular.module("greenmine.controllers.common", [])
module.factory("$data", ["$rootScope", "$q", "resource", DataServiceProvider])
