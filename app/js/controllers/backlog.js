var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    /* Local scope variables */
    $scope.sprintFormOpened = false;

    $scope.calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points);
        var total = 0, assigned = 0, notAssigned = 0, completed = 0;

        _.each($scope.unassingedUs, function(us) {
            total += pointIdToOrder(us.points);
        });

        _.each($scope.milestones, function(ml) {
            _.each(ml.user_stories, function(us) {
                total += pointIdToOrder(us.points);
                assigned += pointIdToOrder(us.points);

                if (us.is_closed) {
                    completed += pointIdToOrder(us.points);
                }
            });
        });

        $scope.stats = {
            totalPoints: total,
            assignedPoints: assigned,
            notAssignedPoints: total - assigned,
            completedPercentage: ((completed * 100) / total).toFixed(1)
        };
    };

    /* Obtain resources */
    rs.getUnassignedUserStories($routeParams.pid)
        .then(function(data) {
            // HACK: because django-filter does not works properly
            // $scope.unassingedUs = data;
            $scope.unassingedUs = _.filter(data, function(item) {
                return (item.project === $rootScope.projectId && item.milestone === null);
            });

            $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order");
            $scope.$apply(function() {
                $scope.$broadcast("userstories-loaded");
            });
        }).then(function() {
            return rs.getMilestones($routeParams.pid);
        }).then(function(data) {
            $scope.$apply(function() {
                // HACK: because django-filter does not works properly
                // $scope.milestones = data;
                $scope.milestones = _.filter(data, function(item) {
                    return item.project === $rootScope.projectId;
                });

                if (data.length > 0) {
                    $scope.sprintId = data[0].id;
                }
            });
        }).then(function() {
            return rs.getUsPoints($scope.projectId);
        }).then(function(data) {
            $scope.$apply(function() {
                $rootScope.constants.points = {};
                $rootScope.constants.pointsList = _.sortBy(data, "order");

                _.each(data, function(item) {
                    $rootScope.constants.points[item.id] = item;
                });

                $scope.$broadcast("points:loaded");
            });
        }).then(function(data) {
            $scope.$apply(function() { $scope.calculateStats(); });
        });
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var BacklogUserStoriesCtrl = function($scope, $rootScope, rs) {
    /* Local scope variables */
    $scope.filtersOpened = false;
    $scope.usFormOpened = false;
    $scope.form = {};

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
        $scope.calculateStats();

        _.each($scope.unassingedUs, function(item) {
            if (item.isModified()) {
                item.save();
                //console.log(item.id, item.order, item.subject);
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


    /* User Story Form */

    $scope.isSameAs = function(property, id) {
        return ($scope.form[property] === parseInt(id, 10));
    };

    $scope.submitUs = function() {
        if ($scope.form.save === undefined) {
            rs.createUserStory($scope.projectId, $scope.form).
                then(function(us) {
                    $scope.$apply(function() {
                        $scope.usFormOpened = false;
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
                    $scope.usFormOpened = false;
                });
            });
        }
    };

    $scope.editUs = function(us) {
        $scope.form = us;
        $scope.usFormOpened = true;
    }

    $scope.removeUs = function(us) {
        us.remove().then(function() {
            $scope.$apply(function() {
                var index = $scope.unassingedUs.indexOf(us);
                $scope.unassingedUs.splice(index, 1);
                $scope.calculateStats();

                generateTagList();
                filterUsBySelectedTags();
            });
        });
    };

    $scope.saveUs = function(us, points) {
        us.points = points
        us.save().then(function() {
            $scope.$apply(function() {
                $scope.calculateStats();
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
    $scope.$on("userstories-loaded", function() {
        generateTagList();
        filterUsBySelectedTags();
    });
};

BacklogUserStoriesCtrl.$inject = ['$scope', '$rootScope', 'resource'];


/* Backlog milestones controller. */

var BacklogMilestonesController = function($scope) {
    $scope.sprintSubmit = function() {
        console.log($scope);
    };
};

BacklogMilestonesController.$inject = ['$scope'];


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
        $scope.calculateStats();

        _.each($scope.ml.user_stories, function(item) {
            if (item.isModified()) {
                item.save();
                //console.log(item.id, item.order, item.subject);
            }
        });
    };

    $scope.$on("points:loaded", calculateStats);
    $scope.$on("sortable:changed", normalizeMilestones);
};

BacklogMilestoneController.$inject = ['$scope'];


