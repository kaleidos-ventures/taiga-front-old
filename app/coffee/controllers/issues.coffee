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
    $scope.filtersData = {}
    $scope.sortingOrder = 'created_date'
    $scope.sortingReverse = true
    $scope.page = 1
    $scope.showGraphs = false

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

        $scope.currentPage = 0
        filterIssues()

    selectTagIfNotSelected = (tag) ->
        if isTagSelected(tag)
            $scope.selectedTags.push(tag)
        return tag

    generateTagList = ->
        tags = []

        for tagname, tagcount of $scope.filtersData.tags
            tag = {id: tagname, name:tagname, count:tagcount, type: "tags"}
            tags.push(selectTagIfNotSelected(tag))

        $scope.tags = tags

    generateAssignedToTags = ->
        makeTag = (user) ->

        tags = []
        for userId, count of $scope.filtersData.assigned_to
            user = $scope.constants.users[userId]
            tag = {
                "id": user.id,
                "name": gm.utils.truncate(user.full_name, 17),
                "count": count,
                "type": "assigned-to"
            }

            tags.push(selectTagIfNotSelected(tag))

        $scope.assignedToTags = tags

    generateStatusTags = ->
        tags = []
        for statusId, count of $scope.filtersData.statuses
            status = $scope.constants.issueStatuses[statusId]
            tag = {"id": status.id, "name": status.name, "count": count, "type":"status", color: status.color}
            tags.push(selectTagIfNotSelected(tag))

        $scope.statusTags = tags

    generateSeverityTags = ->
        tags = []
        for severityId, count of $scope.filtersData.severities
            severity = $scope.constants.severities[severityId]
            tag = {"id": severity.id, "name": severity.name, "count": count, "type": "severity", color: severity.color}
            tags.push(selectTagIfNotSelected(tag))

        $scope.severityTags = tags

    generatePriorityTags = ->
        tags = []
        for priorityId, count of $scope.filtersData.priorities
            priority = $scope.constants.priorities[priorityId]
            tag = {"id": priority.id, "name": priority.name, "count": count, "type": "priority", color: priority.color}
            tags.push(selectTagIfNotSelected(tag))

        $scope.priorityTags = tags

    generateAddedByTags = ->
        tags = []
        for userId, count of $scope.filtersData.owners
            user = $scope.constants.users[userId]
            tag = {
                "id": user.id,
                "name": gm.utils.truncate(user.full_name, 17),
                "count": count,
                "type": "owner"
            }

            tags.push(selectTagIfNotSelected(tag))

        $scope.addedByTags = tags

    regenerateTags = ->
        $scope.selectedTags = []
        generateTagList()
        generateAddedByTags()
        generateAssignedToTags()
        generateSeverityTags()
        generatePriorityTags()
        generateStatusTags()

    getFilterParams = ->

        params = {"page": $scope.page}

        for key, value of _.groupBy($scope.selectedTags, "type")
            params[key] = _.map(value, "id").join(",")

        params["order_by"] = $scope.sortingOrder
        if $scope.sortingReverse
            params["order_by"] = "-#{params["order_by"]}"

        return params

    filterIssues = ->
        $scope.$emit("spinner:start")

        params = getFilterParams()

        rs.getIssues($scope.projectId, params).then (result) ->
            $scope.issues = result.models
            $scope.count = result.count
            $scope.paginatedBy = result.paginatedBy
            $scope.$emit("spinner:stop")

    loadIssuesData = ->
        $scope.selectedMeta = $gmStorage.get("issues-selected-tags") or {}

        promise = rs.getIssuesFiltersData($scope.projectId).then (data) ->
            $scope.filtersData = data
            regenerateTags()
            loadStats()
            return data

        return promise

    loadStats = ->
        rs.getIssuesStats($scope.projectId).then (data) ->
            $scope.issuesStats = data

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            loadIssuesData().then ->
                filterIssues()

    $scope.setPage = (n) ->
        $scope.page = n
        filterIssues()

    $scope.refreshIssues = ->
        loadIssuesData().then ->
            filterIssues()

    $scope.selectTag = selectTag
    $scope.isTagSelected = isTagSelected

    $scope.openCreateIssueForm = ->
        $scope.$broadcast("issue-form:open")

    $scope.toggleShowGraphs = gm.utils.safeDebounced $scope, 500, ->
        $scope.showGraphs = not $scope.showGraphs

    $scope.updateIssueAssignation = (issue, id) ->
        issue.assigned_to = id || null
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssueStatus = (issue, id) ->
        issue.status = id
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssueSeverity = (issue, id) ->
        issue.severity = id

        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssuePriority = (issue, id) ->
        issue.priority = id
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.changeSort = (field, reverse) ->
        $scope.sortingOrder = field
        $scope.sortingReverse = reverse
        filterIssues()

    $scope.removeIssue = (issue) ->
        issue.remove().then ->
            index = $scope.issues.indexOf(issue)
            $scope.issues.splice(index, 1)

            regenerateTags()
            loadStats()
            filterIssues()

    $scope.$on "issue-form:create", (ctx, issue) ->
        $scope.issues.push(issue)

        regenerateTags()
        loadStats()
        filterIssues()


IssuesViewController = ($scope, $location, $rootScope, $routeParams, $q, rs, $data,
                        $confirm, $gmFlash) ->
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

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    loadAttachments = ->
        promise = rs.getIssueAttachments(projectId, issueId)
        promise.then (attachments) ->
            $scope.attachments = attachments

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attachment in $scope.newAttachments
            promise = rs.uploadIssueAttachment(projectId, issueId, attachment)
            promises.push(promise)

        promise = Q.all(promises)
        promise.then ->
            gm.safeApply $scope, ->
                $scope.newAttachments = []
                loadAttachments()

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            loadIssue()
            loadAttachments()
            loadProjectTags()

    $scope.isSameAs = (property, id) ->
        return ($scope.issue[property] == parseInt(id, 10))

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        for key, value of $scope.form
            $scope.issue[key] = value

        $scope.$emit("spinner:start")

        gm.safeApply $scope, ->
            promise = $scope.issue.save()
            promise.then ->
                $scope.$emit("spinner:stop")
                loadIssue()
                saveNewAttachments()
                $gmFlash.info("The issue has been saved")

            promise.then null, (data) ->
                $scope.checksleyErrors = data

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

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value


IssuesFormController = ($scope, $rootScope, $gmOverlay, rs, $gmFlash) ->
    $scope.formOpened = false

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    initialForm = ->
        return {
            status: $scope.project.default_issue_status
            type: $scope.project.default_issue_type
            priority: $scope.project.default_priority
            severity: $scope.project.default_severity}

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        $scope.$emit("spinner:start")
        promise = rs.createIssue($rootScope.projectId, $scope.form)

        promise.then (issue) ->
            $scope.form = initialForm()
            $scope.$emit("spinner:stop")
            $scope.close()
            $rootScope.$broadcast("issue-form:create", issue)
            $gmFlash.info("The issue has been saved")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

    $scope.$on "issue-form:open", (ctx, form) ->
        $scope.form = form || initialForm()
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

        loadProjectTags()

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

module = angular.module("greenmine.controllers.issues", [])
module.controller("IssuesController", ['$scope', '$rootScope', '$routeParams', '$filter',
                  '$q', 'resource', "$data", "$confirm", "$gmStorage", IssuesController])
module.controller("IssuesViewController", ['$scope', '$location', '$rootScope',
                  '$routeParams', '$q', 'resource', "$data", "$confirm", "$gmFlash",
                  IssuesViewController])
module.controller("IssuesFormController", ['$scope', '$rootScope', '$gmOverlay', 'resource',
                  "$gmFlash", IssuesFormController])
