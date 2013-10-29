# Copyright 2013 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

IssuesController = ($scope, $rootScope, $routeParams, $filter, $q, rs, $data, $confirm) ->
    # Global Scope Variables
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        ["Issues", null]
    ]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId

    $scope.filtersOpened = false

    # Pagination variables
    $scope.filteredItems = []
    $scope.groupedItems = []
    $scope.itemsPerPage = 15
    $scope.pagedItems = []
    $scope.currentPage = 0

    $scope.sortingOrder = 'severity'
    $scope.reverse = true

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
        users = $scope.constants.usersList

        $scope.assignedToTags = _.map users, (user) ->
            issues = _.filter($scope.issues, {"assigned_to": user.id})
            return {"id": user.id, "name": user.username, "count": issues.length}

    generateStatusTags = ->
        statuses = $scope.constants.issueStatusesList

        $scope.statusTags = _.map statuses, (status) ->
            issues = _.filter($scope.issues, {"status": status.id})
            return {"id": status.id, "name": status.name, "count": issues.length}

    generateSeverityTags = ->
        severities = $rootScope.constants.severitiesList

        $scope.severityTags = _.map severities, (severity) ->
            issues = _.filter($scope.issues, {"severity": severity.id})
            return {"id": severity.id, "name": severity.name, "count": issues.length}

    generatePriorityTags = ->
        priorities = $rootScope.constants.prioritiesList

        $scope.priorityTags = _.map priorities, (priority) ->
            issues = _.filter($scope.issues, {"priority": priority.id})
            return {"id": priority.id, "name": priority.name, "count": issues.length}

    regenerateTags = ->
        generateTagList()
        generateAssignedToTags()
        generateSeverityTags()
        generatePriorityTags()
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

        # Filter by priority tags
        selectedPriorities = _.filter($scope.priorityTags, "selected")
        if not _.isEmpty(selectedPriorities)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedPriorities, {"id": item.priority})
                item.__hidden = true if not result

        # Filter by severity tags
        selectedSeverities = _.filter($scope.severityTags, "selected")
        if not _.isEmpty(selectedSeverities)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedSeverities, {"id": item.severity})
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

        for issue, i in issues
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

    $scope.openCreateIssueForm = ->
        $scope.$broadcast("issue-form:open")

    $scope.$watch("sortingOrder", groupToPages)
    $scope.$watch("reverse", groupToPages)

    loadIssues = ->
        rs.getIssues($scope.projectId).then (issues) ->
            $scope.issues = issues
            regenerateTags()
            filterIssues()

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            console.log $scope.constants.issueStatuses
            loadIssues()

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

    $scope.removeIssue = (issue) ->
        issue.remove().then ->
            index = $scope.issues.indexOf(issue)
            $scope.issues.splice(index, 1)

            regenerateTags()
            filterIssues()

    $scope.$on "issue-form:create", (ctx, issue) ->
        $scope.issues.push(issue)

        regenerateTags()
        filterIssues()


IssuesViewController = ($scope, $location, $rootScope, $routeParams, $q, rs, $data,
                        $confirm) ->
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        ["Issues", null],
    ]
    $scope.projectId = parseInt($routeParams.pid, 10)

    projectId = $scope.projectId
    issueId = $routeParams.issueid

    $scope.issue = {}
    $scope.form = {}
    $scope.updateFormOpened = false
    $scope.newAttachments = []
    $scope.attachments = []

    loadIssue = ->
        rs.getIssue(projectId, issueId).then (issue) ->
            $scope.issue = issue
            $scope.form = _.extend({}, $scope.issue._attrs)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[1] = ["Issues", $rootScope.urls.issuesUrl(projectId)]
            breadcrumb[2] = ["##{issue.ref}", null]

            $rootScope.pageBreadcrumb = breadcrumb

    loadAttachments = ->
        rs.getIssueAttachments(projectId, issueId).then (attachments) ->
            $scope.attachments = attachments


    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            loadIssue()
            loadAttachments()

    $scope.isSameAs = (property, id) ->
        return ($scope.issue[property] == parseInt(id, 10))

    $scope.submit = ->
        for key, value of $scope.form
            $scope.issue[key] = value

        $scope.issue.save().then ->
            loadIssue()
            saveNewAttachments()
            $rootScope.$broadcast("flash:new", true, "The issue has been saved")

    saveNewAttachments = ->
        _.forEach $scope.newAttachments, (newAttach) ->
            rs.uploadIssueAttachment(projectId, issueId, newAttach).then (attach) ->
                $scope.removeNewAttachment(newAttach)
                $scope.attachments.push(attach)
                $scope.$apply()

    $scope.removeAttachment = (attachment) ->
        $scope.attachments = _.without($scope.attachments, attachment)
        attachment.remove()

    $scope.removeNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)

    $scope.removeIssue = (issue) ->
        promise = $confirm.confirm("Are you sure?")
        promise.then ->
            issue.remove().then ->
                $location.url("/project/#{projectId}/issues/")


IssuesFormController = ($scope, $rootScope, $gmOverlay, rs) ->
    $scope.formOpened = false

    $scope.submit = ->
        promise = rs.createIssue($rootScope.projectId, $scope.form)
        promise.then (issue) ->
            $scope.form = {}
            $scope.close()
            $rootScope.$broadcast("issue-form:create", issue)

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

    $scope.$on "issue-form:open", (ctx, form={}) ->
        $scope.form = form
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false


module = angular.module("greenmine.controllers.issues", [])
module.controller("IssuesViewController", ['$scope', '$location', '$rootScope',
                  '$routeParams', '$q', 'resource', "$data", "$confirm",
                  IssuesViewController])
module.controller("IssuesController", ['$scope', '$rootScope', '$routeParams', '$filter',
                  '$q', 'resource', "$data", "$confirm", IssuesController])
module.controller("IssuesFormController", ['$scope', '$rootScope', '$gmOverlay', 'resource',
                  IssuesFormController])
