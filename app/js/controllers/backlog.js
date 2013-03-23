var BacklogController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'backlog';
    $rootScope.pageBreadcrumb = ["Project", "Backlog"];

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
    };

    rs.getMilestones($routeParams.pid).
        then(onMilestonesLoaded);


    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;
        $scope.filterUsBySelectedTags()
    }

    $scope.generateTagList = function() {
        var tagsDict = {};
        var tags = [];

        _.each($scope.unassingedUs, function(us) {
            _.each(us.tags, function(tag) {
                if (tagsDict[tag.id] === undefined) {
                    tagsDict[tag.id] = true;
                    tags.push(tag);
                }
            });
        });

        $scope.tags = tags;
    };

    $scope.filterUsBySelectedTags = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.id });

        if (selectedTagsIds.length > 0) {
            _.each($scope.unassingedUs, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag.id; });
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

};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];
