var MyModelCtrl = function($scope) {
    console.log("MyModelCtrl", $scope);
};

MyModelCtrl.$inject = ['$scope'];

var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];
    $rootScope.projectId = $routeParams.pid;

    /* Local scope variables */
    $scope.filtersOpened = false;
    $scope.usFormOpened = false;
    $scope.sprintFormOpened = false;

    /* Load unassigned user stories */
    var q1 = rs.getUnassignedUserStories($routeParams.pid).then(function(data) {
        $scope.unassingedUs = data;
        $scope.generateTagList();
        $scope.filterUsBySelectedTags();
        $scope.$apply();
    });

    /* Load milestones */
    var q2 = rs.getMilestones($routeParams.pid).then(function(data) {
        $scope.$apply(function() {
            $scope.milestones = data;

            if (data.length > 0) {
                $scope.sprintId = data[0].id;
            }
        });
    });

    Q.allResolved([q1,q2]).done(function() {
        console.log("DONE");
        $scope.$apply(function() {
            $scope.calculateStats();
        });
    });

    /* Load developers list */
    rs.projectDevelopers($routeParams.pid).then(function(data) {
        $scope.$apply(function() {
            $scope.developers = data;
        });
    });

    $scope.calculateStats = function() {
        var total = 0, assigned = 0, notAssigned = 0, completed = 0;

        _.each($scope.unassingedUs, function(us) {
            total += us.points;
        });

        _.each($scope.milestones, function(ml) {
            _.each(ml.user_stories, function(us) {
                total += us.points;
                assigned += us.points;

                if (us.is_closed) {
                    completed += us.points;
                }
            });
        });

        $scope.totalPoints = total;
        $scope.assignedPoints = assigned;
        $scope.notAssignedPoints = total - assigned;
        $scope.completedPercentage = ((completed * 100) / total).toFixed(1);
    };

    /* Scope methods */
    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;
        $scope.filterUsBySelectedTags()
    }

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

                if (intersection.length === 0) {
                    item.hidden = true;
                } else {
                    item.hidden = false;
                }
            });
        } else {
            _.each($scope.unassingedUs, function(item) {  item.hidden = false; });
        }
    };

    /* Directive event handlers */
    $scope.$on("backlog-resort", function() {
        // Assign new order to unassingedUs.
        _.each($scope.unassingedUs, function(o, y) { o.order = y });
        // TODO: make bulk save.
        // console.log($scope.unassingedUs[0].subject)
        $scope.calculateStats();
    });
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var BacklogUserStoryController = function($scope) {
    $scope.saveUserStory = function(us, points) {
        // Change points value on a model
        us.points = points

        // Calculate new stats
        $scope.calculateStats();
    };
};

BacklogUserStoryController.$inject = ['$scope'];
