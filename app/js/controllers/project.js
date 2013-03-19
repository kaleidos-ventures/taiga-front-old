var ProjectListController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'projects';

    $scope.projects = [
        {name: "Project1"},
        {name: "Project2"},
        {name: "Project3"}
    ];
};

ProjectListController.$inject = ['$scope', '$rootScope', 'url'];
