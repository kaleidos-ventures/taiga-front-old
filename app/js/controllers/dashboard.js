var DashboardController = function($scope, $rootScope, $routeParams, $q, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'dashboard';
    $rootScope.pageBreadcrumb = ["Project", "Dashboard"];
    $rootScope.projectId = $routeParams.pid;
    $scope.sprintId = $routeParams.sid;
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
            if ($scope.userstories[task.user_story] === undefined) {
                return true;
            };

            usTasks[task.user_story][task.status].push(task);
        });

        $scope.usTasks = usTasks;
    };

    var calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope.constants.points);
        var totalTasks = $scope.tasks.length,
            totalUss = $scope.userstoriesList.length,
            totalPoints = 0,
            completedPoints = 0,
            compledUss = 0,
            completedTasks = 0;

        _.each($scope.userstoriesList, function(us) {
            totalPoints += pointIdToOrder(us.points);
        })

        _.each($scope.tasks, function(task) {
            if ($scope.statuses[task.status].is_closed) {
                completedTasks += 1;
            }
        });

        _.each($scope.usTasks, function(statuses, usId) {
            var hasOpenTasks = false;

            var completedTasks = 0;
            var totalTasks = 0;

            _.each(statuses, function(tasks, statusId) {
                totalTasks += tasks.length;

                if ($scope.statuses[statusId].is_closed) {
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

            var us = $scope.userstories[usId];
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

    $q.all([
        rs.getTaskStatuses(projectId),
        rs.getMilestoneUserStories(projectId, sprintId),
        rs.getUsPoints(projectId),
        rs.getTasks(projectId, sprintId),
        rs.getUsers(projectId)
    ]).then(function(results) {
        var statuses = results[0]
          , userstories = results[1]
          , points = results[2]
          , tasks = results[3]
          , users = results[4];

        $rootScope.constants.usersList = _.sortBy(users, "id");

        $scope.statusesList = _.sortBy(statuses, 'id')
        $scope.userstoriesList = _.sortBy(userstories, 'id');

        $scope.userstories = {};
        $scope.statuses = {};

        _.each(statuses, function(status) { $scope.statuses[status.id] = status; });
        _.each(userstories, function(us) { $scope.userstories[us.id] = us; });

        _.each(points, function(item) { $rootScope.constants.points[item.id] = item; });
        _.each(users, function(item) { $rootScope.constants.users[item.id] = item; });

        $scope.tasks = tasks
        $scope.tasks = _.filter(tasks, function(task) {
            // HACK
            return (task.milestone == sprintId && task.project == projectId);
        });

        formatUserStoryTasks();
        calculateStats();
    });

    $scope.form = {};
    $scope.submitTask = function() {
        var form = _.extend({tags:[]}, $scope.form, {"user_story": this.us.id});

        rs.createTask(projectId, form).
            then(function(model) {
                $scope.tasks.push(model);

                formatUserStoryTasks();
                calculateStats();
                $scope.form = {};
            });

        /* Notify to all modal directives
         * for close all opened modals. */
        $scope.$broadcast("modals:close");
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

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource'];

var DashboardUserStoryController = function($scope, $q) {
};

DashboardUserStoryController.$inject = ['$scope', '$q'];


var DashboardTaskController = function($scope, $q) {
    $scope.updateTaskAssignation = function(task, obj) {
        task.assigned_to = obj ? obj.id: null;
        task.save();
    };
};

dashboardtaskcontroller.$inject = ['$scope', '$q'];
