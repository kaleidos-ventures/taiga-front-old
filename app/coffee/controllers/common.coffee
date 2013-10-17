DataServiceProvider = ($rootScope, $q, rs) ->
    service = {}

    service.loadProject = ($scope) ->
        promise = rs.getProject($scope.projectId).then (project) ->
            $scope.project = project
            $rootScope.$broadcast("project:loaded", project)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[0] = project.name
            $rootScope.pageBreadcrumb = breadcrumb

            # USs
            for item in project.points
                $scope.constants.points[item.id] = item
                $scope.constants.pointsByOrder[item.order] = item
            $scope.constants.pointsList = _.sortBy(project.points, "order")
            $rootScope.$broadcast("points:loaded", project.points)
            _.each(project.us_statuses, (status) -> $scope.constants.usStatuses[status.id] = status)
            $scope.constants.usStatusesList = _.sortBy(project.us_statuses, 'id')

            # Tasks
            _.each(project.task_statuses, (item) -> $scope.constants.taskStatuses[item.id] = item)
            $scope.constants.taskStatusesList = _.sortBy(project.task_statuses, "order")

            # issue
            _.each(project.severities, (item) -> $scope.constants.severities[item.id] = item)
            $scope.constants.severitiesList = _.sortBy(project.severities, "order")
            _.each(project.priorities, (item) -> $scope.constants.priorities[item.id] = item)
            $scope.constants.prioritiesList = _.sortBy(project.priorities, "order")
            _.each(project.issue_types, (item) -> $scope.constants.issueTypes[item.id] = item)
            $scope.constants.issueTypesList = _.sortBy(project.issue_types, "order")
            _.each(project.issue_statuses, (item) -> $scope.constants.issueStatuses[item.id] = item)
            $scope.constants.issueStatusesList = _.sortBy(project.issue_statuses, "order")

        return promise

    service.loadTaskboardData = ($scope) ->
        promise = $q.all [
            rs.getTasks($scope.projectId, $scope.sprintId),
            rs.getMilestone($scope.projectId, $scope.sprintId),
        ]

        promise = promise.then (results) ->
            [tasks, milestone] = results
            $scope.milestone = milestone

            userstories = milestone.user_stories

            $scope.userstories = {}
            _.each(userstories, (us) -> $scope.userstories[us.id] = us)
            $scope.userstoriesList = _.sortBy(userstories, 'id')
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

    service.loadUsersAndRoles = ($scope) ->
        promise = $q.all [
            rs.getUsers($scope.projectId),
            rs.getRoles($scope.projectId),
        ]

        promise = promise.then (results) ->
            [users, roles] = results

            $scope.constants.usersList = _.sortBy(users, "id")
            $scope.constants.rolesList = roles
            $scope.constants.computableRolesList = _.filter(roles, "computable")

            _.each(users, (item) -> $scope.constants.users[item.id] = item)

            $rootScope.$broadcast("roles:loaded", roles)
            $rootScope.$broadcast("users:loaded", users)
            return results
        return promise
    return service

module = angular.module("greenmine.controllers.common", [])
module.factory("$data", ["$rootScope", "$q", "resource", DataServiceProvider])
