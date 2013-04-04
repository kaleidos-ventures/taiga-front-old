var DashboardController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'dashboard';
    $rootScope.pageBreadcrumb = ["Project", "Dashboard"];
    $rootScope.projectId = $routeParams.pid;
    $scope.statuses = []

    var projectId = $routeParams.pid;
    var sprintId = $routeParams.sid || 1;

    var formatUserStoryTasks = function() {
        var usTasks = {};

        _.each($scope.userstories, function(us) {
            usTasks[us.id] = {};

            _.each($scope.statuses, function(status) {
                usTasks[us.id][status.id] = [];
            });
        });

        _.each($scope.tasks, function(task) {
            // HACK: filters not works properly
            if ($scope.userstoriesMap[task.user_story] === undefined) {
                return true;
            };

            usTasks[task.user_story][task.status].push(task);
        });

        $scope.usTasks = usTasks;
    };

    var calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope.constants.points);
        var totalTasks = $scope.tasks.length,
            totalUss = $scope.userstories.length,
            totalPoints = 0,
            completedPoints = 0,
            compledUss = 0,
            completedTasks = 0;

        _.each($scope.userstories, function(us) {
            totalPoints += pointIdToOrder(us.points);
        })

        _.each($scope.tasks, function(task) {
            if ($scope.statusesMap[task.status].is_closed) {
                completedTasks += 1;
            }
        });

        _.each($scope.usTasks, function(statuses, usId) {
            var hasOpenTasks = false;

            var completedTasks = 0;
            var totalTasks = 0;

            _.each(statuses, function(tasks, statusId) {
                totalTasks += tasks.length;

                if ($scope.statusesMap[statusId].is_closed) {
                    completedTasks += tasks.length;
                } else {
                    if (tasks.length > 0) {
                        hasOpenTasks = true;
                    }
                }
            });

            if (!hasOpenTasks) {
                compledUss += 1;
            }

            var us = $scope.userstoriesMap[usId];
            var points = pointIdToOrder(us.points);

            completedPoints += ((completedTasks * points) / totalTasks) || 0;
        });

        $scope.stats = {
            totalPoints: totalPoints,
            completedPoints: completedPoints.toFixed(0),
            percentageCompletedPoints: ((completedPoints*100) / totalPoints).toFixed(1),
            totalUss: totalUss,
            compledUss: compledUss.toFixed(0),
            totalTasks: totalTasks,
            completedTasks: completedTasks
        };
    };

    /* Load resources */
    rs.getTaskStatuses(projectId)
        .then(function(statuses) {
            $scope.statuses = statuses;
            $scope.statusesMap = {};

            _.each(statuses, function(status) {
                $scope.statusesMap[status.id] = status;
            });

            return rs.getMilestoneUserStories(projectId, sprintId);
        }).then(function(userstories) {
            $scope.userstories = userstories;
            $scope.userstoriesMap = {};

            _.each(userstories, function(us) {
                $scope.userstoriesMap[us.id] = us;
            });

            return rs.getUsPoints(projectId);
        }).then(function(points) {
            _.each(points, function(item) {
                $rootScope.constants.points[item.id] = item;
            });

            return rs.getTasks(projectId, sprintId);
        }).then(function(tasks) {
            $scope.tasks = tasks

            // HACK:
            $scope.tasks = _.filter(tasks, function(task) {
                return (task.milestone == sprintId && task.project == projectId);
            });

            formatUserStoryTasks();
            calculateStats();
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

        calculateStats();
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
