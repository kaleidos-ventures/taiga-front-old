var DashboardController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';

    $scope.milestones = [
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20}
    ];
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
