var IssuesController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues"];

    $scope.filtersOpened = false;
    $scope.issueFormOpened = false;

    /* Load unassigned user stories */

    var onIssuesLoaded = function(data) {
        $scope.issues = data;
        $scope.generateTagList();
        $scope.filterIssuesBySelectedTags();
    };

    rs.getIssues($routeParams.pid).
        then(onIssuesLoaded);

    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;

        $scope.filterIssuesBySelectedTags()
    }

    $scope.generateTagList = function() {
        var tagsDict = {};
        var tags = [];

        _.each($scope.issues, function(us) {
            _.each(us.tags, function(tag) {
                if (tagsDict[tag.id] === undefined) {
                    tagsDict[tag.id] = true;
                    tags.push(tag);
                }
            });
        });

        $scope.tags = tags;
    };

    $scope.filterIssuesBySelectedTags = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.id });

        if (selectedTagsIds.length > 0) {
            _.each($scope.issues, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag.id; });
                var intersection = _.intersection(selectedTagsIds, itemTagIds);

                if (intersection.length === 0) {
                    item.hidden = true;
                } else {
                    item.hidden = false;
                }
            });
        } else {
            _.each($scope.issues, function(item) {  item.hidden = false; });
        }
    };
};

IssuesController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];

//var BacklogUserStoryController = function($scope) {
//    $scope.saveUserStory = function(us) {
//        console.log("save us:", us);
//    };
//};
//
//BacklogUserStoryController.$inject = ['$scope'];
