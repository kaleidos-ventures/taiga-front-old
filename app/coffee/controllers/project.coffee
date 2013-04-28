@ProjectListController = ($scope, $rootScope, rs) ->
    $rootScope.pageSection = 'projects'

    rs.getProjects().then (projects) ->
        $scope.projects = projects

@ProjectListController.$inject = ['$scope', '$rootScope', 'resource']
