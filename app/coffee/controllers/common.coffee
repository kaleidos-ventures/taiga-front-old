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
        ]

        promise = promise.then (results) ->
            [severities, priorities, users] = results

            $rootScope.constants.severityList = _.sortBy(severities, "order")
            $rootScope.constants.priorityList = _.sortBy(priorities, "order")
            $rootScope.constants.usersList = _.sortBy(users, "id")

            _.each(severities, (item) -> $rootScope.constants.severity[item.id] = item)
            _.each(priorities, (item) -> $rootScope.constants.priority[item.id] = item)
            _.each(users, (item) -> $rootScope.constants.users[item.id] = item)

            return results

        return promise
    return service

module = angular.module("greenmine.controllers.common", [])
module.factory("$data", ["$rootScope", "$q", "resource", DataServiceProvider])
