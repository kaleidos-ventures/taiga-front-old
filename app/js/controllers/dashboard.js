var DashboardController = function($scope, $rootScope, $routeParams, rs) {
    var projectId = $routeParams.pid;
    var sprintId = $routeParams.sid || 1;

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

        $scope.usTasks = usTasks;
    };

    /* Load user stories */

    var loadSuccess_userStoriesByProject = function(data) {
        $scope.userstories = data;
        $scope.formatUserStoryTasks();
    };

    rs.userStoriesByProject(projectId, sprintId).
        then(loadSuccess_userStoriesByProject);

    /* Load developers list */

    var loadSuccessProjectDevelopers = function(data) {
        $scope.developers = data;
    };

    rs.projectDevelopers(projectId).
        then(loadSuccessProjectDevelopers);

    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var DashboardTaskController = function($scope, $q) {
    $scope.saveTask = function(task) {
    };
};

DashboardTaskController.$inject = ['$scope', '$q'];
