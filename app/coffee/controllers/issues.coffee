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

IssuesController = ($scope, $rootScope, $routeParams, $filter, $q, rs, $data, $confirm, $gmStorage) ->
    # Global Scope Variables
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        ["Issues", null]
    ]

    $rootScope.projectId = parseInt($routeParams.pid, 10)
    $scope.filtersOpened = false

    # Pagination variables
    $scope.filteredItems = []
    $scope.groupedItems = []
    $scope.itemsPerPage = 15
    $scope.pagedItems = []
    $scope.currentPage = 0

    $scope.sortingOrder = 'severity'
    $scope.reverse = true

    #####
    ## Tags generation functions
    #####

    $scope.selectedTags = []
    $scope.selectedMeta = {}

    generateTagId = (tag) ->
        return "#{tag.type}-#{tag.id or tag.name}"

    isTagSelected = (tag) ->
        return $scope.selectedMeta[generateTagId(tag)] == true

    selectTag = (tag) ->
        if $scope.selectedMeta[generateTagId(tag)] == undefined
            $scope.selectedMeta[generateTagId(tag)] = true
            $scope.selectedTags.push(tag)
        else
            delete $scope.selectedMeta[generateTagId(tag)]
            $scope.selectedTags = _.reject($scope.selectedTags,
                                        (x) -> generateTagId(tag) == generateTagId(x))


        $gmStorage.set("issues-selected-tags", $scope.selectedMeta)

        # tag.selected = if tag.selected then false else true
        $scope.currentPage = 0
        filterIssues()

    selectTagIfNotSelected = (tag) ->
        if isTagSelected(tag)
            $scope.selectedTags.push(tag)
        return tag

    generateTagList = ->
        tagsDict = {}
        tags = []

        for iss in $scope.issues
            for tag in iss.tags
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        for key, val of tagsDict
            tag = {name:key, count:val, type: "tag"}
            tags.push(selectTagIfNotSelected(tag))

        $scope.tags = tags

    generateAssignedToTags = ->
        makeTag = (user) ->
            issues = _.filter($scope.issues, {"assigned_to": user.id})
            return {
                "id": user.user, "name": gm.utils.truncate(user.full_name, 17),
                "count": issues.length, "type": "assigned-to"
            }

        $scope.assignedToTags = Lazy($scope.project.memberships)
                                    .map(makeTag)
                                    .map(selectTagIfNotSelected).toArray()

    generateStatusTags = ->
        makeTag = (status) ->
            issues = _.filter($scope.issues, {"status": status.id})
            return {"id": status.id, "name": status.name, "count": issues.length, "type":"status"}

        $scope.statusTags = Lazy($scope.constants.issueStatusesList)
                                .map(makeTag)
                                .map(selectTagIfNotSelected).toArray()

    generateSeverityTags = ->
        makeTag = (severity) ->
            issues = _.filter($scope.issues, {"severity": severity.id})
            return {"id": severity.id, "name": severity.name, "count": issues.length, "type": "severity"}

        $scope.severityTags = Lazy($rootScope.constants.severitiesList)
                                .map(makeTag)
                                .map(selectTagIfNotSelected).toArray()

    generatePriorityTags = ->
        makeTag = (priority) ->
            issues = _.filter($scope.issues, {"priority": priority.id})
            return {"id": priority.id, "name": priority.name, "count": issues.length, "type": "priority"}

        $scope.priorityTags = Lazy($rootScope.constants.prioritiesList)
                                .map(makeTag)
                                .map(selectTagIfNotSelected).toArray()

    regenerateTags = ->
        $scope.selectedTags = []
        generateTagList()
        generateAssignedToTags()
        generateSeverityTags()
        generatePriorityTags()
        generateStatusTags()

    #####
    ## Filters functions
    #####

    filterIssues = ->
        for issue in $scope.issues
            issue.__hidden = false

        # Filter by generic tags
        # selectedTagsIds = _($scope.tags).filter("selected").map("name").value()
        selectedTagsIds = _($scope.tags)
                            .filter((x) -> isTagSelected(x))
                            .map("name").value()

        if selectedTagsIds.length > 0
            for item in $scope.issues
                interSection = _.intersection(selectedTagsIds, item.tags)

                if interSection.length == 0
                    item.__hidden = true
                else
                    item.__hidden = false

        # Filter by assigned to tags
        selectedUsers = _.filter($scope.assignedToTags, (x) -> isTagSelected(x))

        if not _.isEmpty(selectedUsers)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedUsers, {"id": item.assigned_to})
                item.__hidden = true if not result

        # Filter by priority tags
        selectedPriorities = _.filter($scope.priorityTags, (x) -> isTagSelected(x))
        if not _.isEmpty(selectedPriorities)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedPriorities, {"id": item.priority})
                item.__hidden = true if not result

        # Filter by severity tags
        selectedSeverities = _.filter($scope.severityTags, (x) -> isTagSelected(x))
        if not _.isEmpty(selectedSeverities)
            for item in $scope.issues
                continue if item.__hidden

                result = _.some(selectedSeverities, {"id": item.severity})
                item.__hidden = true if not result

        # Filter by status tags
        selectedStatuses = _.filter($scope.statusTags, (x) -> isTagSelected(x))
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

    $scope.selectTag = selectTag
    $scope.isTagSelected = isTagSelected

    $scope.openCreateIssueForm = ->
        $scope.$broadcast("issue-form:open")

    $scope.$watch("sortingOrder", groupToPages)
    $scope.$watch("reverse", groupToPages)

    loadIssues = ->
        $scope.selectedMeta = $gmStorage.get("issues-selected-tags") or {}

        rs.getIssues($scope.projectId).then (issues) ->
            $scope.issues = issues
            regenerateTags()
            filterIssues()

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
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

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attrachment in $scope.newAttachments
            promise = rs.uploadIssueAttachment(projectId, issueId, attrachment)
            promises.push(promise)

        promise = Q.all(promises)
        promise.then ->
            $scope.newAttachments = []
            loadAttachments()

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            loadIssue()
            loadAttachments()

    $scope.isSameAs = (property, id) ->
        return ($scope.issue[property] == parseInt(id, 10))

    $scope.submit = gm.utils.debounced 400, ->
        for key, value of $scope.form
            $scope.issue[key] = value

        promise = $scope.issue.save()

        promise.then ->
            loadIssue()
            saveNewAttachments()
            $rootScope.$broadcast("flash:new", true, "The issue has been saved")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

        $scope.$apply()

    $scope.removeAttachment = (attachment) ->
        promise = $confirm.confirm("Are you sure?")
        promise.then () ->
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

    initialForm = ->
        return {
            status: $scope.project.default_issue_status
            type: $scope.project.default_issue_type
            priority: $scope.project.default_priority
            severity: $scope.project.default_severity}

    $scope.submit = gm.utils.debounced 400, ->
        promise = rs.createIssue($rootScope.projectId, $scope.form)

        promise.then (issue) ->
            $scope.form = initialForm()
            $scope.close()
            $rootScope.$broadcast("issue-form:create", issue)
            $rootScope.$broadcast("flash:new", true, "The issue has been saved")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

    $scope.$on "issue-form:open", (ctx, form) ->
        $scope.form = form || initialForm()
        console.log $scope.form
        console.log $scope.constants.issueStatusesList
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false


module = angular.module("greenmine.controllers.issues", [])
module.controller("IssuesController", ['$scope', '$rootScope', '$routeParams', '$filter',
                  '$q', 'resource', "$data", "$confirm", "$gmStorage", IssuesController])
module.controller("IssuesViewController", ['$scope', '$location', '$rootScope',
                  '$routeParams', '$q', 'resource', "$data", "$confirm",
                  IssuesViewController])
module.controller("IssuesFormController", ['$scope', '$rootScope', '$gmOverlay', 'resource',
                  IssuesFormController])
