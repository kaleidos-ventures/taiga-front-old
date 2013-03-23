var DashboardController = function($scope, $rootScope, $routeParams, rs) {
    $rootScope.pageSection = 'backlog';

    $scope.formatUserStoryTasks = function() {
        var usTasks = {};
        var statuses = ['new','inprogress', 'readytest', 'finished', 'rejected'];

        _.each($scope.userstories, function(item) {
            if (usTasks[item.id] === undefined) {
                usTasks[item.id] = {};
                _.each(statuses, function(statusname){
                    usTasks[item.id][statusname] = [];
                });
            }

            _.each(item.tasks, function(task) {
                usTasks[item.id][task.status_id].push(task);
            });
        });

        $scope.usTasks = usTasks
    };

    /* Load user stories */
    var projectId = $routeParams.pid;
    rs.userStoriesByProject(projectId).then(function(data) {
        $scope.userstories = data;
        $scope.formatUserStoryTasks();
    }, function(data) {
        console.log("Error loading user stories");
    });
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];
