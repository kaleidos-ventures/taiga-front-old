var DashboardController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';

    $scope.milestones = [
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20}
    ];

    $scope.userstories = [
        {id:1, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10,
            tasks: [
                {id:1, name:"Task 1", status_id:"new"}
            ]
        }
    ];

    $scope.formatUserStoryTasks = function() {
        var usTasks = {};

        _.each($scope.userstories, function(item) {
            if (usTasks[item.id] === undefined) {
                var tasks = usTasks[item.id] = {};
            }

            _.each(item.tasks, function(task) {
                if (tasks[task.status_id] === undefined) {
                    tasks[task.status_id] = [];
                }

                tasks[task.status_id].push(task);
            });
        });

        $scope.usTasks = usTasks
    };

    $scope.formatUserStoryTasks();
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
