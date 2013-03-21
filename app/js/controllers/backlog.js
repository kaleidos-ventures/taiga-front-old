var BacklogController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';

    $scope.filtersOpened = false;
    $scope.usFormOpened = false;
    $scope.sprintFormOpened = false;

    $scope.allUnassingedUs = [
        {id:1, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10},
        {id:2, points:2, priority:"hight", tags:[{"name": "tag2", id:2}, {"name": "tag2", id:2}], subject:"Sample User story 2", order:10},
        {id:3, points:2, priority:"hight", tags:[{"name": "tag3", id:3}, {"name": "tag2", id:2}], subject:"Sample User story 3", order:10},
        {id:4, points:2, priority:"hight", tags:[{"name": "tag4", id:4}, {"name": "tag2", id:2}], subject:"Sample User story 4", order:10},
        {id:5, points:2, priority:"hight", tags:[{"name": "tag5", id:5}, {"name": "tag2", id:2}], subject:"Sample User story 5", order:10},
        {id:6, points:2, priority:"hight", tags:[{"name": "tag6", id:6}, {"name": "tag2", id:2}], subject:"Sample User story 6", order:10}
    ];

    $scope.milestones = [
        {name:"Milestone3", percentage_completed:20, total_points:100, completed_points:20, us: [
            {id:11, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10},
            {id:12, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 2", order:10},
            {id:13, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 3", order:10},
            {id:14, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 4", order:10},
            {id:15, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 5", order:10},
            {id:16, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 6", order:10}
        ]},
        {name:"Milestone2", percentage_completed:20, total_points:100, completed_points:20, us: [
            {id:21, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10},
            {id:22, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 2", order:10},
            {id:23, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 3", order:10},
            {id:24, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 4", order:10},
            {id:25, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 5", order:10},
            {id:22, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 6", order:10}
        ]},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20, us: [
            {id:31, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10},
            {id:32, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 2", order:10},
            {id:33, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 3", order:10},
            {id:34, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 4", order:10},
            {id:35, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 5", order:10},
            {id:36, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 6", order:10}
        ]},
    ];

    $scope.selectTag= function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;
        $scope.filterUsBySelectedTags()
    }

    $scope.generateTagList = function() {
        var tagsDict = {};
        var tags = [];

        _.each($scope.allUnassingedUs, function(us) {
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

        if (selectedTagsIds.length === 0) {
            $scope.unassingedUs = $scope.allUnassingedUs;
        } else {
            $scope.unassingedUs = _.filter($scope.allUnassingedUs, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag.id; });
                var intersection = _.intersection(selectedTagsIds, itemTagIds);

                if (intersection.length > 0){
                    return true;
                }
                return false;
            });
        }
    };

    $scope.generateTagList();
    $scope.filterUsBySelectedTags();
};

BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
