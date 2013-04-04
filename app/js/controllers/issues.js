var IssuesController = function($scope, $rootScope, $routeParams, $filter, $q, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues"];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    var projectId = $rootScope.projectId;

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

        var issues = _.filter($scope.issues, function(issue) {
                return (issue.__hidden !== true);
        });

        issues = $filter("orderBy")(issues, $scope.sortingOrder, $scope.reverse);

        _.each(issues, function(issue, i) {
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


    $scope.$watch("sortingOrder", groupToPages);
    $scope.$watch("reverse", groupToPages);

    $q.all([
        rs.getIssueTypes(projectId),
        rs.getIssueStatuses(projectId),
        rs.getSeverities(projectId),
        rs.getPriorities(projectId),
        rs.projectDevelopers(projectId)
    ]).then(function(results) {
        var issueTypes = results[0]
          , issueStatuses = results[1]
          , severities = results[2]
          , priorities = results[3]
          , developers = results[4];

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
        $scope.developers = developers;

        return rs.getIssues(projectId);
    }).then(function(issues) {
        $scope.issues = issues;
        // HACK: because filters not works correctly
        $scope.issues = _.filter(issues, function(issue) {
            return (issue.project === projectId);
        });

        generateTagList();
        filterIssues();
    });


    $scope.saveIssue = function(issue) {
        issue.save()
    };
};

IssuesController.$inject = ['$scope', '$rootScope', '$routeParams', '$filter', '$q', 'resource'];


var IssuesViewController = function($scope, $rootScope, $routeParams, $q, rs) {
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues", "#" + $routeParams.issueid];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    var projectId = $rootScope.projectId;

    $q.all([
        rs.getIssueTypes(projectId),
        rs.getIssueStatuses(projectId),
        rs.getSeverities(projectId),
        rs.getPriorities(projectId),
        rs.projectDevelopers(projectId)
    ]).then(function(results) {
        var issueTypes = results[0]
          , issueStatuses = results[1]
          , severities = results[2]
          , priorities = results[3]
          , developers = results[4];

        $rootScope.constants.typeList = _.sortBy(issueTypes, "order");
        $rootScope.constants.statusList = _.sortBy(issueStatuses, "order");
        $rootScope.constants.severityList = _.sortBy(severities, "order");
        $rootScope.constants.priorityList = _.sortBy(priorities, "order");
        $scope.developers = developers;

        return rs.getIssue($routeParams.issueid);
    }).then(function(issue) {
        $scope.issue = issue;
        $scope.form = _.extend({}, $scope.issue);
    });

    $scope.issue = {};
    $scope.form = {};
    $scope.updateFormOpened = false;

    $scope.isSameAs = function(property, id) {
        return ($scope.issue[property] === parseInt(id, 10));
    };

    $scope.save = function() {
        _.each($scope.form, function(value, key) {
            $scope.issue[key] = value;
        });

        $scope.issue.save().then(function() {
            $scope.updateFormOpened = false;
        });
    };
};

IssuesViewController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource'];
