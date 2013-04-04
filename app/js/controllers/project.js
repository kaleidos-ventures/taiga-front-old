var ProjectListController = function($scope, $rootScope, rs) {
    $rootScope.pageSection = 'projects';

    rs.getProjects().then(function(projects) {
        $scope.projects = projects;
    });
};

ProjectListController.$inject = ['$scope', '$rootScope', 'resource'];
