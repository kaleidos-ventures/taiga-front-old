var IssuesController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues"];

    $scope.filtersOpened = false;
    $scope.issueFormOpened = false;

    /* Pagination variables */

    $scope.filteredItems = [];
    $scope.groupedItems = [];
    $scope.itemsPerPage = 10;
    $scope.pagedItems = [];
    $scope.currentPage = 0;

    $scope.sortingOrder = 'severity';
    $scope.reverse = false;

    var generateTagList = function() {
        var tagsDict = {}, tags = [];

        _.each($scope.issues, function(iss) {
            _.each(iss.tags, function(tag) {
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

    var filterIssues = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.name });

        if (selectedTagsIds.length > 0) {
            _.each($scope.issues, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag; });
                var interSection = _.intersection(selectedTagsIds, itemTagIds);

                if (interSection.length === 0) {
                    item.__hidden = true;
                } else {
                    item.__hidden = false;
                }
            });
        } else {
            _.each($scope.issues, function(item) {  item.__hidden = false; });
        }

        groupToPages();
    };

    var groupToPages = function() {
        $scope.pagedItems = [];

        _($scope.issues).
            filter(function(issue) {
                return (issue.__hidden !== true);
            }).
            each(function(issue, i) {
                if (i % $scope.itemsPerPage === 0) {
                    $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)] = [ issue ];
                } else {
                    $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)].push(issue);
                }
            });
    };

    $scope.prevPage = function () {
        if ($scope.currentPage > 0) {
            $scope.currentPage--;
        }
    };

    $scope.nextPage = function () {
        if ($scope.currentPage < $scope.pagedItems.length - 1) {
            $scope.currentPage++;
        }
    };

    $scope.setPage = function () {
        $scope.currentPage = this.n;
    };

    $scope.range = function(start, end) {
        var ret = [];
        if (!end) {
            end = start;
            start = 0;
        }
        for (var i = start; i < end; i++) {
            ret.push(i);
        }
        return ret;
    };

    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;

        $scope.currentPage = 0;
        filterIssues();
    };

    /* Load Resources */
    Q.allResolved([
        rs.getIssueTypes($scope.projectId),
        rs.getIssueStatuses($scope.projectId),
        rs.getSeverities($scope.projectId),
        rs.getPriorities($scope.projectId)
    ]).spread(function(issueTypes, issueStatuses, severities, priorities) {
        _.each(issueTypes, function(item) {
            $rootScope.constants.type[item.id] = item;
        });

        _.each(issueStatuses, function(item) {
            $rootScope.constants.status[item.id] = item;
        });

        _.each(severities, function(item) {
            $rootScope.constants.severity[item.id] = item;
        });

        _.each(priorities, function(item) {
            $rootScope.constants.priority[item.id] = item;
        });

        $rootScope.constants.typeList = _.sortBy(issueTypes, "order");
        $rootScope.constants.statusList = _.sortBy(issueStatuses, "order");
        $rootScope.constants.severityList = _.sortBy(severities, "order");
        $rootScope.constants.priorityList = _.sortBy(priorities, "order");

        return rs.getIssues($scope.projectId);
    }).then(function(issues) {
        $scope.$apply(function() {
            $scope.issues = issues;

            generateTagList();
            filterIssues();

            console.log(issues);
        })
    });

};

IssuesController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var IssuesViewController = function($scope, $rootScope, $routeParams, rs) {
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues", "#" + $routeParams.issueid];
    $rootScope.projectId = $routeParams.pid;

    $scope.issue = {
        id: $routeParams.issueid,
        subject: "Mcsweeney's shoreditch quis skateboard, 3 wolf moon selfies lo-fi stumptown",
        tags: ["sartorial", "aliquip", "probably"],
        description: "Sartorial aliquip you probably haven't heard of them, " +
            "accusamus intelligentsia scenester culpa twee 3 wolf moon neutra et id. " +
            "Post-ironic fap readymade, whatever small batch ut you probably haven't " +
            "heard of them occupy proident dolore. Wayfarers fugiat nostrud ad " +
            "semiotics, bushwick blog beard kale chips laborum labore aliquip vice " +
            "mustache wolf. Occaecat fugiat culpa iphone cillum, magna incididunt " +
            "90's authentic. Adipisicing deserunt echo park meggings, deep v enim " +
            "pour-over hoodie. Chambray blog truffaut, cardigan before they sold out " +
            "gentrify dolore. Jean shorts meh nostrud, incididunt skateboard godard " +
            "ethnic shoreditch ullamco actually high life.",
        status: 1,
        assigned_to: 1,
        priority: 1
    };

    $scope.form = _.extend({}, $scope.issue);
    $scope.updateFormOpened = false;

    $scope.isSameAs = function(property, id) {
        return ($scope.issue[property] === parseInt(id, 10));
    };

    /* Load developers list */

    var loadSuccessProjectDevelopers = function(data) {
        $scope.developers = data;
    };

    rs.projectDevelopers($routeParams.pid).
        then(loadSuccessProjectDevelopers);


    $scope.save = function() {
        console.log("save");
    };
};

IssuesViewController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];
