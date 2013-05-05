@IssuesController = ($scope, $rootScope, $routeParams, $filter, $q, rs) ->
    # Global Scope Variables
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = ["Project", "Issues"]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId

    $scope.filtersOpened = false
    $scope.issueFormOpened = false

    # Pagination variables
    $scope.filteredItems = []
    $scope.groupedItems = []
    $scope.itemsPerPage = 15
    $scope.pagedItems = []
    $scope.currentPage = 0

    $scope.sortingOrder = 'severity'
    $scope.reverse = false

    generateTagList = ->
        tagsDict = {}
        tags = []

        _.each $scope.issues, (iss) ->
            _.each iss.tags, (tag) ->
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        _.each tagsDict, (val, key) ->
            tags.push({name:key, count:val})

        $scope.tags = tags

    generateAssignedToTags = ->
        users = $rootScope.constants.usersList

        $scope.assignedToTags = _.map users, (user) ->
            issues = _.filter($scope.issues, {"assigned_to": user.id})
            return {"id": user.id, "name": user.username, "count": issues.length}

    generateStatusTags = ->
        statuses = $rootScope.constants.statusList

        $scope.statusTags = _.map statuses, (status) ->
            issues = _.filter($scope.issues, {"status": status.id})
            return {"id": status.id, "name": status.name, "count": issues.length}

    regenerateTags = ->
        generateTagList()
        generateAssignedToTags()
        generateStatusTags()

    filterIssues = ->
        for issue in $scope.issues
            issue.__hidden = false

        # Filter by generic tags
        selectedTags = _.filter($scope.tags, "selected")
        selectedTagsIds = _.map(selectedTags, "name")

        if selectedTagsIds.length > 0
            for item in $scope.issues
                interSection = _.intersection(selectedTagsIds, item.tags)

                if interSection.length == 0
                    item.__hidden = true
                else
                    item.__hidden = false

        # Filter by assigned to tags
        selectedUsers = _.filter($scope.assignedToTags, "selected")

        if not _.isEmpty(selectedUsers)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedUsers, {"id": item.assigned_to})
                item.__hidden = true if not result

        # Filter by status tags
        selectedStatuses = _.filter($scope.statusTags, "selected")
        if not _.isEmpty(selectedStatuses)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedStatuses, {"id": item.status})
                item.__hidden = true if not result

        groupToPages()

    groupToPages = ->
        $scope.pagedItems = []

        issues = _.reject($scope.issues, "__hidden")
        issues = $filter("orderBy")(issues, $scope.sortingOrder, $scope.reverse)

        _.each issues, (issue, i) ->
            if i % $scope.itemsPerPage == 0
                $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)] = [issue]
            else
                $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)].push(issue)

    $scope.prevPage = ->
        if $scope.currentPage > 0
            $scope.currentPage--

    $scope.nextPage = ->
        if $scope.currentPage < ($scope.pagedItems.length - 1)
            $scope.currentPage++

    $scope.setPage = ->
        $scope.currentPage = this.n

    $scope.range = (start, end) ->
        ret = []
        if not end?
            end = start
            start = 0

        ret.push(i) for i in [start..end-1]
        return ret

    $scope.selectTag = (tag) ->
        tag.selected = if tag.selected then false else true

        $scope.currentPage = 0
        filterIssues()

    $scope.$watch("sortingOrder", groupToPages)
    $scope.$watch("reverse", groupToPages)

    promise = $q.all([
        rs.getIssueTypes(projectId),
        rs.getIssueStatuses(projectId),
        rs.getSeverities(projectId),
        rs.getPriorities(projectId),
        rs.getUsers(projectId),
        rs.getIssues(projectId)
    ])

    promise = promise.then (results) ->
        issueTypes = results[0]
        issueStatuses = results[1]
        severities = results[2]
        priorities = results[3]
        users = results[4]
        issues = results[5]

        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)
        _.each(issueTypes, (item) -> $rootScope.constants.type[item.id] = item)
        _.each(issueStatuses, (item) -> $rootScope.constants.status[item.id] = item)
        _.each(severities, (item) -> $rootScope.constants.severity[item.id] = item)
        _.each(priorities, (item) -> $rootScope.constants.priority[item.id] = item)

        $rootScope.constants.typeList = _.sortBy(issueTypes, "order")
        $rootScope.constants.statusList = _.sortBy(issueStatuses, "order")
        $rootScope.constants.severityList = _.sortBy(severities, "order")
        $rootScope.constants.priorityList = _.sortBy(priorities, "order")
        $rootScope.constants.usersList = _.sortBy(users, "id")

        $scope.issues = issues
        regenerateTags()
        filterIssues()

    $scope.updateIssueAssignation = (issue, id) ->
        issue.assigned_to = id || null
        issue.save()
        regenerateTags()

    $scope.updateIssueStatus = (issue, id) ->
        issue.status = id
        issue.save()
        regenerateTags()

    $scope.updateIssueSeverity = (issue, id) ->
        issue.severity = id
        issue.save()
        regenerateTags()

    $scope.updateIssuePriority = (issue, id) ->
        issue.priority = id
        issue.save()
        regenerateTags()

    $scope.submitIssue = ->
        if $scope.form.id is undefined
            rs.createIssue($scope.projectId, $scope.form).then (us) ->
                $scope.form = {}
                $scope.issues.push(us)

                regenerateTags()
                filterIssues()
        else
            $scope.form.save().then ->
                $scope.form = {}
                regenerateTags()
                filterIssues()

        $rootScope.$broadcast("modals:close")

    $scope.removeIssue = (issue) ->
        issue.remove().then ->
            index = $scope.issues.indexOf(issue)
            $scope.issues.splice(index, 1)

            regenerateTags()
            filterIssues()

@IssuesController.$inject = ['$scope', '$rootScope', '$routeParams', '$filter', '$q', 'resource']


@IssuesViewController = ($scope, $rootScope, $routeParams, $q, rs) ->
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = ["Project", "Issues", "#" + $routeParams.issueid]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    issueId = $routeParams.issueid

    $q.all([
        rs.getIssueTypes(projectId),
        rs.getIssueStatuses(projectId),
        rs.getSeverities(projectId),
        rs.getPriorities(projectId),
        rs.getUsers(projectId),
        rs.getIssueAttachments(projectId, issueId),
        rs.getIssue(projectId, issueId)
    ]).then((results) ->
        issueTypes = results[0]
        issueStatuses = results[1]
        severities = results[2]
        priorities = results[3]
        users = results[4]
        attachments = results[5]
        issue = results[6]

        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)
        _.each(issueTypes, (item) -> $rootScope.constants.type[item.id] = item)
        _.each(issueStatuses, (item) -> $rootScope.constants.status[item.id] = item)
        _.each(severities, (item) -> $rootScope.constants.severity[item.id] = item)
        _.each(priorities, (item) -> $rootScope.constants.priority[item.id] = item)

        $rootScope.constants.typeList = _.sortBy(issueTypes, "order")
        $rootScope.constants.statusList = _.sortBy(issueStatuses, "order")
        $rootScope.constants.severityList = _.sortBy(severities, "order")
        $rootScope.constants.priorityList = _.sortBy(priorities, "order")
        $rootScope.constants.usersList = _.sortBy(users, "id")

        $scope.attachments = attachments
        $scope.issue = issue
        $scope.form = _.extend({}, $scope.issue)
    )

    $scope.issue = {}
    $scope.form = {}
    $scope.updateFormOpened = false

    $scope.isSameAs = (property, id) ->
        return ($scope.issue[property] == parseInt(id, 10))

    $scope.save = ->
        defered = $q.defer()
        promise = defered.promise

        if $scope.attachment
            rs.uploadIssueAttachment(projectId, issueId, $scope.attachment).then (data)->
                defered.resolve(data)
        else
            defered.resolve(null)

        promise = promise.then (data) ->
            _.each $scope.form, (value, key) ->
                $scope.issue[key] = value
            return $scope.issue.save()

        promise = promise.then (issue)->
            $scope.updateFormOpened = false
            return issue.refresh()

@IssuesViewController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource']
