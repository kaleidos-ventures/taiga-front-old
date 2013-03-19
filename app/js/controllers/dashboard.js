var DashboardController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';
    console.log($routeParams);

    $scope.tags = [
        {name:"footag", count: 2, id: 1},
        {name:"bartag", count: 3, id: 2},
    ];

    $scope.unassingedUs = [
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story"}
    ];

    $scope.milestones = [
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20}
    ];
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
