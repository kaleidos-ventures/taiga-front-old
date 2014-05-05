# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class IssuesController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$filter", "$q",
                 "resource", "$data", "$confirm", "$modal", "$i18next",
                 "$location", "$favico", "$gmFilters"]

    constructor: (@scope, @rootScope, @routeParams, @filter, @q, @rs, @data,
                  @confirm, @modal, @i18next, @location, @favico, @gmFilters) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        @_toggleShowGraphs = @toggleShowGraphs
        @toggleShowGraphs = gm.utils.safeDebounced @scope, 500, @_toggleShowGraphs

    section: "issues"
    getTitle: ->
        @i18next.t("common.issues")

    initialize: ->
        @.debounceMethods()

        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t("common.issues"), null]
        ]

        @scope.filtersOpened = false
        @scope.filters = {}

        @.selectedFilters = []

        @scope.page = 1
        @scope.showGraphs = false

        @scope.setPage = (n) =>
            @scope.page = n
            @.refreshIssues()

        # Load initial data
        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @.refreshAll()

    # This method is used on template for provide
    # a proper membership list compatible with
    getActiveProjectMembership: ->
        return _.map project.active_memberships, (member) ->
            return {name: member.full_name, id: member.user}
    #####
    ## Refresh page operations
    #####

    refreshIssues: ->
        defered = @q.defer()
        @.loadStats().then =>
            @.loadIssues().then =>
                defered.resolve()
        return defered.promise

    refreshFilters: ->
        defered = @q.defer()
        @.loadIssuesFiltersData().then =>
            @.initializeSelectedFilters()
            defered.resolve()
        return defered.promise

    refreshAll: ->
        @scope.refreshing = true
        promise = @q.all([
            @.refreshFilters(),
            @.refreshIssues()
        ])
        promise.then =>
            @scope.refreshing = false
        return promise

    #####
    ## Filters/Sorting scope functions
    #####

    isFilterSelected: (filterTag) ->
        projectId = @rootScope.projectId
        namespace = "issues"
        return @gmFilters.isFilterSelected(projectId, namespace, filterTag)

    toggleFilter: (filterTag) ->
        ft = _.clone(filterTag, true)
        item = _.find(@.selectedFilters, {type: ft.type, id: ft.id})

        if item is undefined
            @gmFilters.selectFilter(@rootScope.projectId, "issues", filterTag)
            @.selectedFilters.push(ft)
        else
            @gmFilters.unselectFilter(@rootScope.projectId, "issues", filterTag)
            @.selectedFilters = _.reject(@.selectedFilters, item)

        @scope.currentPage = 0

        # Mark selected filters modified
        # for properly dispatch watchers
        @.selectedFilters = _.clone(@.selectedFilters, false)
        @.refreshIssues()

    # Using a $gmFilters service for populate a scope with
    # a fresh list of selected filters state previously persisted
    initializeSelectedFilters: ->
        filters = @gmFilters.getSelectedFiltersList(@rootScope.projectId, "issues", @scope.filters)
        @.selectedFilters = filters

    #####
    ## Load operations.
    #####

    loadIssues: ->
        @scope.$emit("spinner:start")
        params = @gmFilters.makeIssuesQueryParams(@rootScope.projectId, "issues",
                                                  @scope.filters, {page: @scope.page})
        promise = @rs.getIssues(@scope.projectId, params).then (result) =>
            @scope.issues = result.models
            @scope.count = result.count
            @scope.paginatedBy = result.paginatedBy
            @scope.$emit("spinner:stop")

        return promise

    loadIssuesFiltersData: ->
        return @rs.getIssuesFiltersData(@scope.projectId).then (data) =>
            @scope.filters = @gmFilters.generateFiltersForIssues(data.getAttrs(), @scope.constants)
            return data

    loadStats: ->
        return @rs.getIssuesStats(@scope.projectId).then (data) =>
            @scope.issuesStats = data
            @favico.badge(@scope.issuesStats.total_issues - @scope.issuesStats.closed_issues)

    #####
    ## Interface (visual) operations
    #####

    openCreateIssueForm: ->
        promise = @modal.open("issue-form", {"type": "create"})
        promise.then (issue) =>
            @scope.issues.push(issue)
            @refreshIssues()
        return promise

    openEditIssueForm: (issue) ->
        promise = @modal.open("issue-form", {"issue": issue, "type": "edit"})
        promise.then =>
            @refreshIssues()
        return promise

    # Debounced Method (see debounceMethods method)
    toggleShowGraphs: =>
        @scope.showGraphs = not @scope.showGraphs

    updateIssueAssignation: (issue, id) ->
        issue.assigned_to = id || null

        promise = issue.save()
        promise.then =>
            @refreshFilters()

        return promise

    updateIssueStatus: (issue, id) ->
        issue.status = id
        promise = issue.save()
        promise.then =>
            @refreshFilters()

        return promise

    updateIssueSeverity: (issue, id) ->
        issue.severity = id

        promise = issue.save()
        promise.then =>
            @refreshFilters()

        return promise

    updateIssuePriority: (issue, id) ->
        issue.priority = id

        promise = issue.save()
        promise.then =>
            @refreshFilters()

        return promise

    removeIssue: (issue) ->
        issue.remove().then =>
            index = @scope.issues.indexOf(issue)
            @scope.issues.splice(index, 1)
            @refreshIssues()

    openIssue: (projectSlug, issueRef)->
        @location.url("/project/#{projectSlug}/issues/#{issueRef}")


class IssuesViewController extends TaigaDetailPageController
    @.$inject = ["$scope", "$location", "$rootScope", "$routeParams", "$q",
                 "resource", "$data", "$confirm", "$gmFlash", "$i18next",
                 "$favico", "$modal", "$gmFilters", "selectOptions"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @rs, @data,
                  @confirm, @gmFlash, @i18next, @favico, @modal, @gmFilters,
                  @selectOptions) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        @_submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, @_submit

    section: "issues"
    getTitle: ->
        @i18next.t("common.issues")

    uploadAttachmentMethod: "uploadIssueAttachment"
    getAttachmentsMethod: "getIssueAttachments"
    objectIdAttribute: "issueId"

    initialize: ->
        @debounceMethods()

        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t("common.issues"), null],
        ]

        @scope.issue = {}
        @scope.form = {}
        @scope.updateFormOpened = false
        @scope.newAttachments = []
        @scope.attachments = []

        @rs.resolve(pslug: @routeParams.pslug, issueref: @routeParams.ref).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.issueId = data.issue

            @onRemoveUrl = "/project/#{@scope.projectSlug}/issues/"

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @.loadIssue()
                    @.loadAttachments()
                    @.loadProjectTags()

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @selectOptions.colorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.watcherSelectOptions = {
            allowClear: true
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
            containerCssClass: "watchers-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
        }

    issuesQueryParams: ->
        return @gmFilters.getLastIssuesQueryParams(@rootScope.projectId, "issues")

    loadIssue: ->
        params = @.issuesQueryParams()
        promise = @rs.getIssue(@scope.projectId, @scope.issueId, params).then (issue) =>
            @scope.issue = issue
            @scope.form = _.extend({}, @scope.issue._attrs)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            breadcrumb[1] = [@i18next.t("common.issues"), @rootScope.urls.issuesUrl(@scope.projectSlug)]
            breadcrumb[2] = ["##{issue.ref}", null]
            @rootScope.pageTitle = "#{@i18next.t('common.issues')} - ##{issue.ref}"

            @rootScope.pageBreadcrumb = breadcrumb
        return promise

    # Debounced Method (see debounceMethods method)
    submit: =>
        for key, value of @scope.form
            @scope.issue[key] = value

        @scope.$emit("spinner:start")

        promise = @scope.issue.save()
        promise.then =>
            gm.safeApply @scope, =>
                @scope.$emit("spinner:stop")
                @scope.$emit("history:reload")

                @.loadIssue()
                @.saveNewAttachments()
                @gmFlash.info(@i18next.t("issue.issue-saved"))

        promise.then null, (data) =>
            gm.safeApply @scope, =>
                @scope.checksleyErrors = data

        return promise

    openCreateUserStoryForm: () ->
        initializeForm = () =>
            result = {}
            if @scope.issue?
                result["subject"] = @scope.issue.subject
                result["description"] = @scope.issue.description
                result["is_blocked"] = @scope.issue.is_blocked
                result["blocked_note"] = @scope.issue.blocked_note
                result["tags"] = @scope.issue.tags
                result["generated_from_issue"] = @scope.issue.id

            points = {}
            for role in @scope.constants.computableRolesList
                points[role.id] = @scope.project.default_points
            result["points"] = points
            result["project"] = @scope.projectId
            result["status"] = @scope.project.default_us_status

            return result

        promise = @modal.open("generate-user-story-form", {"us": initializeForm(), "type": "create"})
        promise.then =>
            @loadIssue()


class IssuesModalController extends ModalBaseController
    @.$inject = ["$scope", "$rootScope", "$gmOverlay", "resource", "$gmFlash",
                 "$i18next", "$confirm", "$q", "selectOptions"]
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next, @confirm, @q, @selectOptions) ->
        super(scope)

    initialize: ->
        @scope.type = "create"
        @scope.newAttachments = []
        @scope.attachments = []

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @selectOptions.colorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
        }
        super()

    saveNewAttachments: (projectId, issueId) =>
        if @scope.newAttachments.length == 0
            return null

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadIssueAttachment(projectId, issueId, attachment)
            promise.then =>
                @scope.newAttachments = _.without(@scope.newAttachments, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @loadAttachments(projectId, issueId)

        promise.then null, (data) =>
            @loadAttachments(projectId, issueId)
            @gmFlash.error(@i18next.t("common.upload-attachment-error"))

        return promise

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then () =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    loadAttachments: (projectId, issueId) ->
        promise = @rs.getIssueAttachments(projectId, issueId)
        promise.then (attachments) =>
            @scope.attachments = attachments
        return promise

    loadProjectTags: =>
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    openModal: ->
        @loadProjectTags()
        if @scope.context.issue?
            @scope.form = @scope.context.issue
            @loadAttachments(@scope.projectId, @scope.form.id)
        else
            @scope.form = {
                status: @scope.project.default_issue_status
                type: @scope.project.default_issue_type
                priority: @scope.project.default_priority
                severity: @scope.project.default_severity
            }
        @scope.formOpened = true

        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        promise = @gmOverlay.open()
        promise.then =>
            @scope.formOpened = false
        return promise

    # Debounced Method (see debounceMethods method)
    submit: =>
        defered = @q.defer()

        if @scope.form.id?
            promise = @scope.form.save(false)
        else
            promise = @rs.createIssue(@rootScope.projectId, @scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            finishSubmit = =>
                @scope.$emit("spinner:stop")
                @closeModal()
                @gmOverlay.close()
                @scope.defered.resolve(@scope.form)
                @gmFlash.info(@i18next.t("issue.issue-saved"))
                defered.resolve(data)

            if @scope.newAttachments.length > 0
                @saveNewAttachments(@scope.projectId, data.id).then ->
                    finishSubmit()
            else
                finishSubmit()

        promise.then null, (data) =>
            @scope.checksleyErrors = data
            defered.reject(data)

        return promise


class IssueUserStoryModalController extends ModalBaseController
    @.$inject = ["$scope", "$rootScope", "$gmOverlay", "resource", "$gmFlash",
                 "$i18next", "selectOptions"]
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next, @selectOptions) ->
        super(scope)

    initialize: ->
        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @selectOptions.colorizedTags
            containerCssClass: "tags-selector"
        }
        super()

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    openModal: () ->
        @loadProjectTags()
        @scope.formOpened = true
        @scope.form = @scope.context.us

        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        @gmOverlay.open().then =>
            @scope.formOpened = false

    # Debounced Method (see debounceMethods method)
    submit: =>
        @scope.$emit("spinner:start")
        promise = @rs.createUserStory(@scope.form)
        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @gmOverlay.close()
            @scope.defered.resolve()
            @gmFlash.info(@i18next.t("issue.user-story-saved"))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise


moduleDeps = ["gmModal", "taiga.services.filters", "taiga.services.resource",
              "taiga.services.data", "gmConfirm", "favico", "gmOverlay",
              "gmFlash", "i18next", "taiga.services.selectOptions"]
module = angular.module("taiga.controllers.issues", moduleDeps)
module.controller("IssuesController", IssuesController)
module.controller("IssuesViewController", IssuesViewController)
module.controller("IssuesModalController", IssuesModalController)
module.controller("IssueUserStoryModalController", IssueUserStoryModalController)
