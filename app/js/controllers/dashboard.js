var DashboardController = function($scope, $rootScope, $routeParams, rs) {
    var projectId = $routeParams.pid;
    var sprintId = $routeParams.sid || 1;

    $scope.statuses = []

    $scope.formatUserStoryTasks = function() {
        var usTasks = {};

        _.each($scope.userstories, function(item) {
            if (usTasks[item.id] === undefined) {
                usTasks[item.id] = {};
                _.each($scope.statuses, function(status){
                    usTasks[item.id][status.id] = [];
                });
            }

            _.each(item.tasks, function(task) {
                usTasks[item.id][task.status].push(task);
            });
        });

        $scope.usTasks = usTasks;
    };

    /* Load user stories */
    var usPromise = rs.getMilestoneUserStories(projectId, sprintId).
        then(function(userstories) {
            $scope.userstories = userstories;
        });

    /* Load task statuses */
    var statusesPromise = rs.getTaskStatuses(projectId).
        then(function(statuses) {
            $scope.statuses = statuses;
        });

    Q.allResolved([statusesPromise, usPromise]).then(function(promises) {
        $scope.formatUserStoryTasks();
        $scope.$digest();
    });

    /* Load developers list */
    rs.projectDevelopers(projectId).then(function(developers) {
        $scope.developers = developers;
    });

    /* Global Scope Variables */
    $rootScope.pageSection = 'dashboard';
    $rootScope.pageBreadcrumb = ["Project", "Dashboard"];

    $scope.newtaskForm = {};
    $scope.createNewTask = function() {
        var tasksText = $scope.newtaskForm.tasks;
        var tasksUsId = parseInt($scope.newtaskForm.usId, 10);
        $scope.newtaskForm = {};

        var tasks = _.map(tasksText.split("\n"), function(text) {
            var task = {id: _.uniqueId(), name: text, status_id:"new"};
            var tokens = text.split(" ");

            if (tokens[0][0] == "!") {
                if (tokens[0] == "!inprogress") {
                    task.status_id = "inprogress";
                }
                task.name = tokens.splice(1).join(" ");
            }
            return task;
        });

        _.each(tasks, function(task) {
            $scope.usTasks[tasksUsId][task.status_id].push(task);
        });

        /* Notify to all modal directives
         * for close all opened modals. */
        $scope.$broadcast("close-modals");
    };
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];

var DashboardUserStoryController = function($scope, $q) {

};

DashboardUserStoryController.$inject = ['$scope', '$q'];


var DashboardTaskController = function($scope, $q) {
    $scope.saveTask = function(task) {
    };
};

DashboardTaskController.$inject = ['$scope', '$q'];
