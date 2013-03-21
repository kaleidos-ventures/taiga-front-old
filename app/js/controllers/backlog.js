var BacklogController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';

    $scope.filtersOpened = false;
    $scope.usFormOpened = false;
    $scope.sprintFormOpened = false;

    $scope.tags = [
        {name:"footag1", id:1, count:2},
        {name:"bartag2", id:2, count:1},
        {name:"bartag3", id:3, count:2},
        {name:"bartag4", id:4, count:2},
        {name:"bartag5", id:5, count:2},
        {name:"bartag6", id:6, count:2},
        {name:"bartag7", id:7, count:2},
        {name:"bartag8", id:8, count:2},
        {name:"bartag9", id:9, count:2},
        {name:"bartag10", id:10, count:2},
        {name:"bartag11", id:11, count:2},
    ];

    $scope.unassingedUs = [
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 1", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 2", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 3", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 4", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 5", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 6", order:10}
    ];

    $scope.unassingedUs2 = [
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 1", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 2", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 3", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 4", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 5", order:10},
        {points:2, priority:"hight", tags:["kk", "bb"], subject:"Sample User story 6", order:10}
    ];

    $scope.milestones = [
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20}
    ];
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
