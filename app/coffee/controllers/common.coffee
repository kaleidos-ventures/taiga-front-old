DataServiceProvider = ($rootScope, $q, rs, UnassignedUserStories) ->
    service = {}

    service.loadProjectStats = ($scope) ->
        promise = rs.getProjectStats($scope.projectId).then (projectStats) ->
            $scope.projectStats = projectStats
            $rootScope.$broadcast("project_stats:loaded", projectStats)

        return promise

    service.loadProject = ($scope) ->
        promise = rs.getProject($scope.projectId).then (project) ->
            $scope.project = project
            $rootScope.$broadcast("project:loaded", project)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[0] = [project.name, $rootScope.urls.backlogUrl(project.slug)]
            $rootScope.pageBreadcrumb = breadcrumb

            # USs
            for item in project.points
                $scope.constants.points[item.id] = item
                $scope.constants.pointsByOrder[item.order] = item

            $scope.constants.pointsList = _.sortBy(project.points, "order")
            $rootScope.$broadcast("points:loaded", project.points)

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
            $scope.userstoriesList = userstories
            $scope.$emit("stats:reload")
            return results
        return promise

    service.loadUnassignedUserStories = ($scope) ->
        promise = UnassignedUserStories.fetch($rootScope.projectId)
        promise = promise.then (unassignedUs) ->
            $scope.unassignedUs = unassignedUs
            $rootScope.$broadcast("userstories:loaded")
            return $scope.unassignedUs
        return promise

    # NOTE: This method depends on getProject
    service.loadUsersAndRoles = ($scope) ->
        promise = $q.all [
            rs.getUsers($scope.project.id),
            rs.getRoles($scope.project.id),
        ]

        promise = promise.then (results) ->
            [users, roles] = results

            $scope.constants.usersList = _.sortBy(users, "id")
            $scope.constants.rolesList = roles

            _.each(users, (item) -> $scope.constants.users[item.id] = item)

            $rootScope.$broadcast("roles:loaded", roles)
            $rootScope.$broadcast("users:loaded", users)

            availableRoles = _($scope.project.memberships).map("role").uniq().value()

            $scope.constants.computableRolesList = _(roles).filter("computable")
                                                           .filter((x) -> _.contains(availableRoles, x.id))
                                                           .value()
            return results
        return promise

    service.loadSiteInfo = ($scope) ->
        $scope.site = {}

        defered = $q.defer()
        promise = rs.getSiteInfo()
        promise.then (data) ->
            $scope.site = _.merge($scope.site, data)
            defered.resolve($scope.site)

        promise.then null, ->
            defered.reject()

        return defered.promise

    return service

module = angular.module("taiga.controllers.common", [])
module.factory("$data", ["$rootScope", "$q", "resource", "UnassignedUserStories", DataServiceProvider])
