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
            $scope.sprintId = data[0].id;
        }
    });
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var BacklogUserStoriesCtrl = function($scope, $rootScope, rs) {
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

    /* Load developers list */
    rs.projectDevelopers($scope.projectId).
        then(function(data) {
            $scope.$apply(function() { $scope.developers = data; });
        }).
        then(function() {
            return rs.getUsStatuses($scope.projectId);
        }).
        then(function(usstatuses) {
            $scope.$apply(function() { $scope.usstatuses = usstatuses; });
        });

    /* Obtain resources */
    rs.getUnassignedUserStories($scope.projectId).
        then(function(data) {
            // HACK: because django-filter does not works properly
            // $scope.unassingedUs = data;
            $scope.unassingedUs = _.filter(data, function(item) {
                return (item.project === $rootScope.projectId && item.milestone === null);
            });

            $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order");

            $scope.$apply(function() {
                $rootScope.$broadcast("userstories:loaded");
                generateTagList();
                filterUsBySelectedTags();
            });

            return rs.getUsPoints($scope.projectId);
        }).
        then(function(data) {
            $scope.$apply(function() {
                $rootScope.constants.points = {};
                $rootScope.constants.pointsList = _.sortBy(data, "order");

                _.each(data, function(item) {
                    $rootScope.constants.points[item.id] = item;
                });

                calculateStats();
                $rootScope.$broadcast("points:loaded");
            });
        });


    /* User Story Form */
    $scope.submitUs = function() {
        if ($scope.form.id === undefined) {
            rs.createUserStory($scope.projectId, $scope.form).
                then(function(us) {
                    $scope.$apply(function() {
                        $scope.form = {};
                        $scope.unassingedUs.push(us);

                        generateTagList();
                        filterUsBySelectedTags();
                        resortUserStories();
                    });
                });
        } else {
            $scope.form.save().then(function() {
                $scope.$apply(function() {
                    $scope.form = {};
                });
            });
        }

        $rootScope.$broadcast("modals:close");
    };

    $scope.editUs = function(us) {
        $scope.form = us;
    }

    $scope.removeUs = function(us) {
        us.remove().then(function() {
            $scope.$apply(function() {
                var index = $scope.unassingedUs.indexOf(us);
                $scope.unassingedUs.splice(index, 1);

                calculateStats();
                generateTagList();
                filterUsBySelectedTags();
            });
        });
    };

    $scope.saveUsPoints = function(us, points) {
        us.points = points;
        us.save().then(function() {
            $scope.$apply(function() {
                calculateStats();
            });
        }, function(data, status) {
            $scope.$apply(function() {
                us.revert();
            });
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

BacklogUserStoriesCtrl.$inject = ['$scope', '$rootScope', 'resource'];


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
        rs.getMilestones($rootScope.projectId).
            then(function(data) {
                $scope.$apply(function() {

                    // HACK: because django-filter does not works properly
                    // $scope.milestones = data;
                    $scope.milestones = _.filter(data, function(item) {
                        return item.project === $rootScope.projectId;
                    });


                    $scope.$emit("milestones:loaded", $scope.milestones);
                    calculateStats();
                });
            });
    });

    $scope.sprintSubmit = function() {
        if ($scope.form.save === undefined) {
            rs.createMilestone($scope.projectId, $scope.form).then(function(milestone) {
                $scope.$apply(function() {
                    $scope.milestones.unshift(milestone);
                    $scope.form = {};
                    $scope.sprintFormOpened = false;
                });
            });
        } else {
            $scope.form.save().then(function() {
                $scope.$apply(function() {
                    $scope.form = {};
                    $scope.sprintFormOpened = false;
                });
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


