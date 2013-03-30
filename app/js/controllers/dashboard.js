var DashboardController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'dashboard';
    $rootScope.pageBreadcrumb = ["Project", "Dashboard"];
    $rootScope.projectId = $routeParams.pid;

    var projectId = $routeParams.pid;
    var sprintId = $routeParams.sid || 1;

    $scope.statuses = []

    $scope.formatUserStoryTasks = function() {
        var usTasks = {};

        _.each($scope.tasks, function(task) {
            if (usTasks[task.user_story] === undefined) {
                usTasks[task.user_story] = {};

                _.each($scope.statuses, function(status) {
                    usTasks[task.user_story][status.id] = [];
                });
            }

            usTasks[task.user_story][task.status].push(task);
        });

        $scope.usTasks = usTasks;
    };

    /* Load resources */
    rs.getTaskStatuses(projectId)
        .then(function(statuses) {
            $scope.$apply(function() {
                $scope.statuses = statuses;
            });
        }).then(function() {
            return rs.getMilestoneUserStories(projectId, sprintId);
        }).then(function(userstories) {
            $scope.$apply(function() {
                $scope.userstories = userstories;
            });
        }).then(function() {
            return rs.getTasks(projectId, sprintId);
        }).then(function(tasks) {
            $scope.$apply(function() {
                $scope.tasks = tasks
                $scope.formatUserStoryTasks();
                // console.log(tasks);
            });
        });

    /* Load developers list */
    rs.projectDevelopers(projectId).then(function(developers) {
        $scope.developers = developers;
    });


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

    $scope.$on("sortable:changed", function() {
        _.each($scope.usTasks, function(statuses, usId) {
            _.each(statuses, function(tasks, statusId) {
                _.each(tasks, function(task) {
                    task.user_story = parseInt(usId, 10);
                    task.status = parseInt(statusId, 10);

                    if (task.isModified()) {
                        task.save();
                    }
                });
            });
        });
    });
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
