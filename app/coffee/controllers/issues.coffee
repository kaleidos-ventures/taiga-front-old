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

class IssuesController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$routeParams', '$filter', '$q',
                 'resource', '$data', '$confirm', '$modal', '$i18next',
                 '$location', '$favico', 'SelectedTags']
    constructor: (@scope, @rootScope, @routeParams, @filter, @q, @rs, @data, @confirm, @modal, @i18next, @location, @favico, @SelectedTags) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        toggleShowGraphs = @toggleShowGraphs
        @toggleShowGraphs = gm.utils.safeDebounced @scope, 500, toggleShowGraphs

    section: 'issues'
    getTitle: ->
        @i18next.t('common.issues')

    initialize: ->
        @debounceMethods()

        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t('common.issues'), null]
        ]

        @SelectedTags(@rootScope.projectId).issues_order.setDefault({field: 'created_date', reverse: true})

        @scope.filtersOpened = false
        @scope.filtersData = {}
        @scope.sortingOrder = @SelectedTags(@rootScope.projectId).issues_order.getField()
        @scope.sortingReverse = @SelectedTags(@rootScope.projectId).issues_order.isReverse()
        @scope.page = 1
        @scope.showGraphs = false

        @scope.setPage = (n) ->
            @scope.page = n
            @filterIssues()

        # Load initial data
        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @loadIssuesData().then =>
                        @filterIssues()

    issuesQueryParams: ->
        tags = @SelectedTags(@rootScope.projectId).issues.tags.join()
        status = @SelectedTags(@rootScope.projectId).issues.status.join()
        type = @SelectedTags(@rootScope.projectId).issues.type.join()
        severity = @SelectedTags(@rootScope.projectId).issues.severity.join()
        priority = @SelectedTags(@rootScope.projectId).issues.priority.join()
        owner = @SelectedTags(@rootScope.projectId).issues.owner.join()
        assigned_to = @SelectedTags(@rootScope.projectId).issues.assigned_to.join()
        order_by = @SelectedTags(@rootScope.projectId).issues_order.getField()
        if @SelectedTags(@rootScope.projectId).issues_order.isReverse()
            order_by = "-#{order_by}"

        params = {}
        params.tags = tags if tags != ""
        params.status = status if status != ""
        params.type = type if type != ""
        params.severity = severity if severity != ""
        params.priority = priority if priority != ""
        params.owner = owner if owner != ""
        params.assigned_to = assigned_to if assigned_to != ""
        params.order_by = order_by

        return params

    #####
    ## Tags generation functions
    #####

    selectedTags: ->
        _.flatten((tags.values() for tags in _.values(@SelectedTags(@rootScope.projectId).issues)), true)

    isTagSelected: (tag) ->
        return @SelectedTags(@rootScope.projectId).issues[tag.type].fetch(tag)?

    toggleTag: (tag) ->
        tags = @SelectedTags(@rootScope.projectId).issues[tag.type]
        if tags.fetch(tag)?
            tags.remove(tag)
        else
            tags.store(tag)

        @scope.currentPage = 0
        @filterIssues()

    refreshSelectedTags:  ->
        _.forEach @SelectedTags(@rootScope.projectId).issues, (tagGroup) =>
            _.forEach tagGroup.values(), (storedTag) =>
                newTag = _.find(@scope[tagGroup.constructor.scopeVar], {id: storedTag.id})
                if newTag
                    tagGroup.update(storedTag, newTag)

    generateTagsFromList: (list, constants, type, scopeVar) ->
        tags = []
        for value in list
            [id, count] = value
            element = constants[id]
            tag = {
                id: element.id,
                name: element.name,
                count: count,
                type: type,
                color: element.color
            }
            tags.push(tag)

        @scope[scopeVar] = tags

    generateTagsFromUsers: (list, type, scopeVar) ->
        tags = []
        for userCounter in list
            if userCounter[0] is null
                tag = {
                    id: "null",
                    name: @i18next.t("common.unassigned"),
                    count: userCounter[1],
                    type: type
                }
            else
                user = @scope.constants.users[userCounter[0]]
                tag = {
                    id: user.id,
                    name: gm.utils.truncate(user.full_name, 17),
                    count: userCounter[1],
                    type: type
                }

            tags.push(tag)

        @scope[scopeVar] = _.sortBy tags, (item) ->
            if item.id == "null"
                # NOTE: This is a hack to order users by full name but set
                #       "Unassigned" as the first element. \o/ \o/ \o/ \o/
                return "0000000000000000"
            return item.name

    generateTagList: ->
        tags = []

        for tagCounter in @scope.filtersData.tags
            tag = {id: tagCounter[0], name: tagCounter[0], count: tagCounter[1], type: "tags"}
            tags.push(tag)

        @scope.tags = tags

    regenerateTags: ->
        @generateTagsFromList(@scope.filtersData.statuses, @scope.constants.issueStatuses, "status", "statusTags")
        @generateTagsFromList(@scope.filtersData.types, @scope.constants.types, "type", "typeTags")
        @generateTagsFromList(@scope.filtersData.severities, @scope.constants.severities, "severity", "severityTags")
        @generateTagsFromList(@scope.filtersData.priorities, @scope.constants.priorities, "priority", "priorityTags")
        @generateTagsFromUsers(@scope.filtersData.owners, "owner", "addedByTags")
        @generateTagsFromUsers(@scope.filtersData.assigned_to, "assigned_to", "assignedToTags")
        @generateTagList()

    getFilterParams: ->
        params = {"page": @scope.page}

        for key, value of _.groupBy(@selectedTags(), "type")
            params[key] = _.map(value, "id").join(",")

        params["order_by"] = @scope.sortingOrder
        if @scope.sortingReverse
            params["order_by"] = "-#{params["order_by"]}"

        return params

    filterIssues: ->
        @scope.$emit("spinner:start")

        params = @getFilterParams()

        @rs.getIssues(@scope.projectId, params).then (result) =>
            @scope.issues = result.models
            @scope.count = result.count
            @scope.paginatedBy = result.paginatedBy
            @scope.$emit("spinner:stop")

    loadIssuesData: ->
        promise = @rs.getIssuesFiltersData(@scope.projectId).then (data) =>
            @scope.filtersData = data
            @regenerateTags()
            @refreshSelectedTags()
            @loadStats()
            return data

        return promise

    loadStats: ->
        @rs.getIssuesStats(@scope.projectId).then (data) =>
            @scope.issuesStats = data
            @favico.badge(@scope.issuesStats.total_issues - @scope.issuesStats.closed_issues)

    refreshIssues: ->
        @scope.refreshing = true
        @loadIssuesData().then =>
            @filterIssues().then =>
                @scope.refreshing = false

    openCreateIssueForm: ->
        promise = @modal.open("issue-form", {'type': 'create'})
        promise.then (issue) =>
            @scope.issues.push(issue)
            @refreshIssues()

    openEditIssueForm: (issue) ->
        promise = @modal.open("issue-form", {'issue': issue, 'type': 'edit'})
        promise.then =>
            @refreshIssues()

    # Debounced Method (see debounceMethods method)
    toggleShowGraphs: =>
        @scope.showGraphs = not @scope.showGraphs

    updateIssueAssignation: (issue, id) ->
        issue.assigned_to = id || null
        issue.save().then =>
            @refreshIssues()

    updateIssueStatus: (issue, id) ->
        issue.status = id
        issue.save().then =>
            @refreshIssues()

    updateIssueSeverity: (issue, id) ->
        issue.severity = id

        issue.save().then =>
            @refreshIssues()

    updateIssuePriority: (issue, id) ->
        issue.priority = id
        issue.save().then =>
            @refreshIssues()

    changeSort: (field, reverse) ->
        @SelectedTags(@rootScope.projectId).issues_order.set field: field, reverse: reverse
        @scope.sortingOrder = field
        @scope.sortingReverse = reverse
        @filterIssues()

    removeIssue: (issue) ->
        issue.remove().then =>
            index = @scope.issues.indexOf(issue)
            @scope.issues.splice(index, 1)
            @refreshIssues()

    openIssue: (projectSlug, issueRef)->
        @location.url("/project/#{projectSlug}/issues/#{issueRef}")


class IssuesViewController extends TaigaPageController
    @.$inject = ['$scope', '$location', '$rootScope', '$routeParams', '$q',
                 'resource', '$data', '$confirm', '$gmFlash', '$i18next',
                 '$favico']
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @rs, @data, @confirm, @gmFlash, @i18next, @favico) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    section: 'issues'
    getTitle: ->
        @i18next.t('common.issues')

    initialize: ->
        @debounceMethods()
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t('common.issues'), null],
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

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @loadIssue()
                    @loadAttachments()
                    @loadHistorical()
                    @loadProjectTags()

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @tagsSelectOptionsShowColorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.watcherSelectOptions = {
            allowClear: true
            formatResult: @watcherSelectOptionsShowMember
            formatSelection: @watcherSelectOptionsShowMember
            containerCssClass: "watchers-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @assignedToSelectOptionsShowMember
            formatSelection: @assignedToSelectOptionsShowMember
        }

    issuesQueryParams: ->
        return @location.search()

    loadIssue: ->
        params = @issuesQueryParams()
        @rs.getIssue(@scope.projectId, @scope.issueId, params).then (issue) =>
            @scope.issue = issue
            @scope.form = _.extend({}, @scope.issue._attrs)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            breadcrumb[1] = [@i18next.t('common.issues'), @rootScope.urls.issuesUrl(@scope.projectSlug)]
            breadcrumb[2] = ["##{issue.ref}", null]
            @rootScope.pageTitle = "#{@i18next.t('common.issues')} - ##{issue.ref}"

            @rootScope.pageBreadcrumb = breadcrumb

    loadHistorical: (page=1) ->
        @rs.getIssueHistorical(@scope.issueId, {page: page}).then (historical) =>
            if @scope.historical and page != 1
                historical.models = _.union(@scope.historical.models, historical.models)

            @scope.showMoreHistoricaButton = historical.models.length < historical.count
            @scope.historical = historical

    loadMoreHistorical: ->
        page = if @scope.historical then @scope.historical.current + 1 else 1
        @loadHistorical(page=page)

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    loadAttachments: ->
        promise = @rs.getIssueAttachments(@scope.projectId, @scope.issueId)
        promise.then (attachments) =>
            @scope.attachments = attachments

    saveNewAttachments: =>
        if @scope.newAttachments.length == 0
            return

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadIssueAttachment(@scope.projectId, @scope.issueId, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @scope.newAttachments = []
                @loadAttachments()

    # Debounced Method (see debounceMethods method)
    submit: =>
        for key, value of @scope.form
            @scope.issue[key] = value

        @scope.$emit("spinner:start")

        gm.safeApply @scope, =>
            promise = @scope.issue.save()
            promise.then =>
                @scope.$emit("spinner:stop")
                @loadIssue()
                @loadHistorical()
                @saveNewAttachments()
                @gmFlash.info(@i18next.t("issue.issue-saved"))

            promise.then null, (data) =>
                @scope.checksleyErrors = data

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    removeIssue: (issue) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then =>
            issue.remove().then =>
                @location.url("/project/#{@scope.projectSlug}/issues/")

    tagsSelectOptionsShowColorizedTags: (option, container) =>
        hash = hex_sha1(option.text.trim().toLowerCase())
        color = hash
            .substring(0,6)
            .replace('8','0')
            .replace('9','1')
            .replace('a','2')
            .replace('b','3')
            .replace('c','4')
            .replace('d','5')
            .replace('e','6')
            .replace('f','7')

        container.parent().css('background', "##{color}")
        container.text(option.text)
        return

    watcherSelectOptionsShowMember: (option, container) =>
        member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
        # TODO: Make me more beautiful and elegant
        return "<span style=\"padding: 0px 5px;
                              border-left: 15px solid #{member.color}\">#{member.full_name}</span>"

    assignedToSelectOptionsShowMember: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: Make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
         return "<span\">#{option.text}</span>"


class IssuesModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash',
                 '$i18next', '$confirm', '$q']
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next, @confirm, @q) ->
        super(scope)

    initialize: ->
        @scope.type = "create"
        @scope.newAttachments = []
        @scope.attachments = []

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @tagsSelectOptionsShowColorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @assignedToSelectOptionsShowMember
            formatSelection: @assignedToSelectOptionsShowMember
        }
        super()

    saveNewAttachments: (projectId, issueId) =>
        if @scope.newAttachments.length == 0
            return

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadIssueAttachment(projectId, issueId, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @scope.newAttachments = []
        return promise

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    loadAttachments: (projectId, issueId) ->
        promise = @rs.getIssueAttachments(projectId, issueId)
        promise.then (attachments) ->
            @scope.attachments = attachments

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

        @gmOverlay.open().then =>
            @scope.formOpened = false

    # Debounced Method (see debounceMethods method)
    submit: =>
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
                @gmFlash.info(@i18next.t('issue.issue-saved'))

            if @scope.newAttachments.length > 0
                @saveNewAttachments(@scope.projectId, data.id).then =>
                    finishSubmit()
            else
                finishSubmit()

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    tagsSelectOptionsShowColorizedTags: (option, container) =>
        hash = hex_sha1(option.text.trim().toLowerCase())
        color = hash
            .substring(0,6)
            .replace('8','0')
            .replace('9','1')
            .replace('a','2')
            .replace('b','3')
            .replace('c','4')
            .replace('d','5')
            .replace('e','6')
            .replace('f','7')

        container.parent().css('background', "##{color}")
        container.text(option.text)
        return

    assignedToSelectOptionsShowMember: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
        return "<span\">#{option.text}</span>"


module = angular.module("taiga.controllers.issues", [])
module.controller("IssuesController", IssuesController)
module.controller("IssuesViewController", IssuesViewController)
module.controller("IssuesModalController", IssuesModalController)
