SearchController = ($scope, $rootScope, $routeParams, rs) ->
    $rootScope.pageSection = 'search'
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.term = $routeParams.term

    rs.getProject($rootScope.projectId).then (project) ->
        $rootScope.project = project
        $rootScope.pageBreadcrumb = [project.name, "Search"]
        $rootScope.$broadcast("project:loaded", project)

    rs.search($rootScope.projectId, $routeParams.term).then (results) ->
        $scope.results = _.groupBy(results, "model_name")


module = angular.module("greenmine.controllers.search", [])
module.controller("SearchController", ["$scope", "$rootScope", "$routeParams", "resource", SearchController])
