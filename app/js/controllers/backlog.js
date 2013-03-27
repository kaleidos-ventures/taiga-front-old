var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];
    $rootScope.projectId = $routeParams.pid;

    $scope.filtersOpened = false;
    $scope.usFormOpened = false;
    $scope.sprintFormOpened = false;

    /* Load unassigned user stories */

    var onUnassignedUserstoriesLoaded = function(data) {
        $scope.unassingedUs = data;
        $scope.generateTagList();
        $scope.filterUsBySelectedTags();
    };

    rs.getUnassignedUserStories($routeParams.pid).
        then(onUnassignedUserstoriesLoaded);

    /* Load milestones */

    var onMilestonesLoaded = function(data) {
        $scope.milestones = data;

        if (data.length > 0) {
            $scope.sprintId = data[0].id;
        }
    };

    rs.getMilestones($routeParams.pid).
        then(onMilestonesLoaded);

    /* Load developers list */

    var loadSuccessProjectDevelopers = function(data) {
        $scope.developers = data;
    };

    rs.projectDevelopers($routeParams.pid).
        then(loadSuccessProjectDevelopers);

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
    });
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];

var BacklogUserStoryController = function($scope) {
    $scope.saveUserStory = function(us) {
        console.log("save us:", us);
    };
};

BacklogUserStoryController.$inject = ['$scope'];
