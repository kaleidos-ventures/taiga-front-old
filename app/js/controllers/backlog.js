var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];
    $rootScope.projectId = parseInt($routeParams.pid, 10);
    $scope.stats = {};

    $scope.$on("stats:update", function(ctx, data) {
        if (data.notAssignedPoints) {
            $scope.stats.notAssignedPoints = data.notAssignedPoints;
        }

        if (data.completedPoints) {
            $scope.stats.completedPoints = data.completedPoints;
        }

        if (data.assignedPoints) {
            $scope.stats.assignedPoints = data.assignedPoints;
        }

        var total = ($scope.stats.notAssignedPoints || 0) +
                         ($scope.stats.assignedPoints || 0);

        var completed = $scope.stats.completedPoints || 0;

        $scope.stats.completedPercentage = ((completed * 100) / total).toFixed(1)
        $scope.stats.totalPoints = total;
    });

    $scope.$on("milestones:loaded", function(ctx, data) {
        if (data.length > 0) {
            $rootScope.sprintId = data[0].id;
        }
    });
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var BacklogUserStoriesCtrl = function($scope, $rootScope, $q, rs) {
    /* Local scope variables */
    $scope.filtersOpened = false;
    $scope.form = {};

    var calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points);
        var total = 0;

        _.each($scope.unassingedUs, function(us) {
            total += pointIdToOrder(us.points);
        });

        $scope.$emit("stats:update", {
            "notAssignedPoints": total
        });
    };

    var generateTagList = function() {
        var tagsDict = {}, tags = [];

        _.each($scope.unassingedUs, function(us) {
            _.each(us.tags, function(tag) {
                if (tagsDict[tag] === undefined) {
                    tagsDict[tag] = 1;
                } else {
                    tagsDict[tag] += 1;
                }
            });

        });

        _.each(tagsDict, function(val, key) {
            tags.push({name:key, count:val});
        });

        $scope.tags = tags;
    };

    var filterUsBySelectedTags = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.name });

        if (selectedTagsIds.length > 0) {
            _.each($scope.unassingedUs, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag; });
                var interSection = _.intersection(selectedTagsIds, itemTagIds);

                if (interSection.length === 0) {
                    item.__hidden = true;
                } else {
                    item.__hidden = false;
                }
            });
        } else {
            _.each($scope.unassingedUs, function(item) {  item.__hidden = false; });
        }
    };

    var resortUserStories = function() {
        // Normalize user stories array
        _.each($scope.unassingedUs, function(item, index) {
            item.order = index;
            item.milestone = null;
        });

        // Sort again
        $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order");

        // Calculte new stats
        calculateStats();

        _.each($scope.unassingedUs, function(item) {
            if (item.isModified()) {
                item.save();
            }
        });
    };

    $q.all([
        rs.getUsers($scope.projectId),
        rs.getUsStatuses($scope.projectId)
    ]).then(function(results) {
        $scope.users = results[0];
        $scope.usstatuses = results[1];
    });

    $q.all([
        rs.getUnassignedUserStories($scope.projectId),
        rs.getUsPoints($scope.projectId),
    ]).then(function(results) {
        var unassingedUs = results[0]
          , usPoints = results[1];

        // HACK: because django-filter does not works properly
        // $scope.unassingedUs = data;
        $scope.unassingedUs = _.filter(unassingedUs, function(item) {
            return (item.project === $rootScope.projectId && item.milestone === null);
        });

        $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order");

        $rootScope.constants.points = {};
        $rootScope.constants.pointsList = _.sortBy(usPoints, "order");

        _.each(usPoints, function(item) {
            $rootScope.constants.points[item.id] = item;
        });

        generateTagList();
        filterUsBySelectedTags();
        calculateStats();

        $rootScope.$broadcast("points:loaded");
        $rootScope.$broadcast("userstories:loaded");
    });

    /* User Story Form */
    $scope.submitUs = function() {
        if ($scope.form.id === undefined) {
            rs.createUserStory($scope.projectId, $scope.form).
                then(function(us) {
                    $scope.form = {};
                    $scope.unassingedUs.push(us);

                    generateTagList();
                    filterUsBySelectedTags();
                    resortUserStories();
                });
        } else {
            $scope.form.save().then(function() {
                $scope.form = {};
                generateTagList();
                filterUsBySelectedTags();
                resortUserStories();
            });
        }

        $rootScope.$broadcast("modals:close");
    };

    /* Pre edit user story hook. */
    $scope.initEditUs = function(us) {
        if (us !== undefined) {
            $scope.form = us;
        } else {
            $scope.form = {tags: []};
        }
    };

    /* Cancel edit user story hook. */
    $scope.cancelEditUs = function() {
        if ($scope.form) {
            if ($scope.form.revert !== undefined) {
                $scope.form.revert();
            }

            $scope.form = {};
        }
    };

    $scope.removeUs = function(us) {
        us.remove().then(function() {
            var index = $scope.unassingedUs.indexOf(us);
            $scope.unassingedUs.splice(index, 1);

            calculateStats();
            generateTagList();
            filterUsBySelectedTags();
        });
    };

    $scope.saveUsPoints = function(us, id) {
        us.points = id;
        us.save().then(calculateStats, function(data, status) {
            us.revert();
        });
    };

    /* User Story Filters */
    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;
        filterUsBySelectedTags()
    };

    /* Signal Handlign */
    $scope.$on("sortable:changed", resortUserStories);
};

BacklogUserStoriesCtrl.$inject = ['$scope', '$rootScope', '$q', 'resource'];


/* Backlog milestones controller. */

var BacklogMilestonesController = function($scope, $rootScope, rs) {
    /* Local scope variables */
    $scope.sprintFormOpened = false;

    var calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points);
        var assigned = 0, completed = 0;

        _.each($scope.milestones, function(ml) {
            _.each(ml.user_stories, function(us) {
                assigned += pointIdToOrder(us.points);

                if (us.is_closed) {
                    completed += pointIdToOrder(us.points);
                }
            });
        });
        $scope.$emit("stats:update", {
            "assignedPoints": assigned,
            "completedPoints": completed
        });
    };

    $scope.$on("points:loaded", function() {
        rs.getMilestones($rootScope.projectId).then(function(data) {
            // HACK: because django-filter does not works properly
            // $scope.milestones = data;
            $scope.milestones = _.filter(data, function(item) {
                return item.project === $rootScope.projectId;
            });

            calculateStats();

            $scope.$emit("milestones:loaded", $scope.milestones);
        });
    });

    $scope.sprintSubmit = function() {
        if ($scope.form.save === undefined) {
            rs.createMilestone($scope.projectId, $scope.form).then(function(milestone) {
                $scope.milestones.unshift(milestone);

                // Clear the current form after creating
                // of new sprint is completed
                $scope.form = {};
                $scope.sprintFormOpened = false;

                // Update the sprintId value for correct
                // linking of dashboard menu item to the
                // last created milestone
                $rootScope.sprintId = milestone.id
            });
        } else {
            $scope.form.save().then(function() {
                $scope.form = {};
                $scope.sprintFormOpened = false;
            });
        }
    };
};

BacklogMilestonesController.$inject = ['$scope', '$rootScope', 'resource'];


/* One backlog milestone controller */

var BacklogMilestoneController = function($scope, rs) {
    var calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points);
        var total = 0, completed = 0;

        _.each($scope.ml.user_stories, function(us) {
            total += pointIdToOrder(us.points);

            if (us.is_closed) {
                completed += pointIdToOrder(us.points);
            }
        });

        $scope.stats = {
            total: total,
            completed: completed,
            percentage: ((completed * 100) / total).toFixed(1)
        };
    };

    var normalizeMilestones = function() {
        _.each($scope.ml.user_stories, function(item, index) {
            item.milestone = $scope.ml.id;
        });

        // Calculte new stats
        calculateStats();

        _.each($scope.ml.user_stories, function(item) {
            if (item.isModified()) {
                item.save();
            }
        });
    };

    calculateStats()
    //$scope.$on("points:loaded", calculateStats);
    $scope.$on("sortable:changed", normalizeMilestones);
};

BacklogMilestoneController.$inject = ['$scope'];
