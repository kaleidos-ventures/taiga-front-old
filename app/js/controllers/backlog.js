var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    /* Local scope variables */
    $scope.sprintFormOpened = false;

    /* Load unassigned user stories */
    var promise1 = rs.getUnassignedUserStories($routeParams.pid).then(function(data) {

        // HACK: because django-filter does not works properly
        // $scope.unassingedUs = data;
        $scope.unassingedUs = _.filter(data, function(item) {
            return (item.project === $rootScope.projectId && item.milestone === null);
        });

        $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order");

        $scope.$apply(function() {
            $scope.$broadcast("userstories-loaded");
        });
    });

    /* Load milestones */
    var promise2 = rs.getMilestones($routeParams.pid).then(function(data) {
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
    });

    var promise3 = rs.getUsPoints($scope.projectId).then(function(data) {
        $scope.$apply(function() {
            $rootScope.constants.points = {};

            _.each(data, function(item) {
                $rootScope.constants.points[item.id] = item;
            });
        });
    });

    Q.allResolved([promise1, promise2, promise3]).done(function() {
        $scope.$apply(function() { $scope.calculateStats(); });
    });

    $scope.calculateStats = function() {
        var pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope);;
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
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var BacklogUserStoriesCtrl = function($scope, $rootScope, rs) {
    /* Local scope variables */
    $scope.filtersOpened = false;
    $scope.usFormOpened = false;

    /* Load developers list */
    rs.projectDevelopers($scope.projectId).then(function(data) {
        $scope.$apply(function() {
            $scope.developers = data;
        });
    });


    $scope.saveUserStory = function(us, points) {
        console.log("saveUserStory", points);
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

    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;
        $scope.filterUsBySelectedTags()
    };

    $scope.generateTagList = function() {
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

    $scope.filterUsBySelectedTags = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.name });

        if (selectedTagsIds.length > 0) {
            _.each($scope.unassingedUs, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag; });
                var intersection = _.intersection(selectedTagsIds, itemTagIds);

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

    $scope.$on("backlog-resort", function() {
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
    });

    $scope.$on("userstories-loaded", function() {
        $scope.generateTagList();
        $scope.filterUsBySelectedTags();
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

var BacklogMilestoneController = function($scope) {
    var pointIdToOrder = greenmine.utils.pointIdToOrder($scope);

    $scope.calculateStats = function() {
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

    $scope.calculateStats();

    $scope.$on("backlog-resort", function() {
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
    });
};

BacklogMilestoneController.$inject = ['$scope'];


