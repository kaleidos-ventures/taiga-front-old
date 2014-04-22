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


class KanbanController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$q", "resource",
                 "$data","$modal", "$model", "$i18next", "$favico", "$gmFilters"]

    constructor: (@scope, @rootScope, @routeParams, @q, @rs, @data,
                  @modal, @model, @i18next, @favico, @gmFilters) ->
        super(scope, rootScope, favico)

    section: "kanban"
    getTitle: ->
        @i18next.t("common.kanban")

    initialize: ->
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t("common.kanban"), null]
        ]

        # Main: entry point
        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @.reloadUserStories()

    reloadUserStories: ->
        @data.loadUserStories(@scope).then =>
            @.initializeFilters()
            @.formatUserStories()

    initializeFilters: ->
        @.filters = @gmFilters.generateFiltersForKanban(@scope.userstories, @scope.constants)
        @.selectedFilters = @gmFilters.getSelectedFiltersList(@rootScope.projectId, "kanban-filter", @.filters)

    isFilterSelected: (filterTag) ->
        projectId = @rootScope.projectId
        namespace = "kanban-filter"
        return @gmFilters.isFilterSelected(projectId, namespace, filterTag)

    toggleFilter: (filterTag) ->
        ft = _.clone(filterTag, true)
        item = _.find(@.selectedFilters, {type: ft.type, id: ft.id})

        if item is undefined
            @gmFilters.selectFilter(@rootScope.projectId, "kanban-filter", filterTag)
            @.selectedFilters.push(ft)
        else
            @gmFilters.unselectFilter(@rootScope.projectId, "kanban-filter", filterTag)
            @.selectedFilters = _.reject(@.selectedFilters, item)

        # Mark modified for properly run watch dispatchers.
        @.selectedFilters = _.clone(@.selectedFilters, false)
        @.formatUserStories()

    resortUserStories: (statusId)->
        for item, index in @.uss[statusId]
            item.order = index

        modifiedUs = _.filter(@.uss[statusId], (x) -> x.isModified())
        bulkData = _.map(@.uss[statusId], (value, index) -> [value.id, index])

        for item in modifiedUs
            item._moving = true

        promise = @rs.updateBulkUserStoriesOrder(@scope.projectId, bulkData)
        promise = promise.then ->
            for us in modifiedUs
                us.markSaved()
                us._moving = false

        return promise

    # TODO: in future this function should be moved to service for proper
    # share it with backlog.
    filterUserStories: ->
        if @.selectedFilters.length == 0
            for item in @scope.userstories
                item.__hidden = false
        else
            for item in @scope.userstories
                itemTags = @gmFilters.getFiltersForUserStory(item)
                selectedTags = _.map(@.selectedFilters, @gmFilters.filterToText)
                if _.intersection(selectedTags, itemTags).length == 0
                    item.__hidden = true
                else
                    item.__hidden = false

    prepareForRenderUserStories: ->
        @.uss = {}
        for status in @scope.constants.usStatusesList
            @.uss[status.id] = []

        for us in @scope.userstories
            @.uss[us.status]?.push(us)
        return

    formatUserStories: ->
        @.filterUserStories()
        @.prepareForRenderUserStories()
        @scope.$broadcast("kanban:redraw")

    saveUsPoints: (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        us._moving = true
        promise = us.save()
        promise.then =>
            us._moving = false
            @scope.$broadcast("points:changed")

        promise.then null, (data, status) ->
            us._moving = false
            us.revert()

    saveUsStatus: (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) ->
            data._moving = false

    initializeUsForm: (us, status) ->
        if us?
            return us

        result = {}
        result["project"] = @scope.projectId
        result["status"] = status or @scope.project.default_us_status
        points = {}
        for role in @scope.constants.computableRolesList
            points[role.id] = @scope.project.default_points
        result["points"] = points
        return result

    openCreateUsForm: (statusId) ->
        promise = @modal.open("us-form", {"us": @initializeUsForm(null, statusId), "type": "create"})
        promise.then (us) =>
            newUs = @model.make_model("userstories", us)
            @scope.userstories.push(newUs)
            @.formatUserStories()

    openEditUsForm: (us) ->
        promise = @modal.open("us-form", {"us": @initializeUsForm(us, us.status or null), "type": "edit"})
        promise.then =>
            @formatUserStories()

    sortableOnAdd: (us, index, sortableScope) =>
        us.status = sortableScope.status.id

        us._moving = true
        us.save().then =>
            if @scope.project.is_backlog_activated
                @.uss[sortableScope.status.id].splice(us.order, 0, us)
            else
                @.uss[sortableScope.status.id].splice(index, 0, us)
                @.resortUserStories(sortableScope.status.id)
            us._moving = false

    sortableOnUpdate: (uss, sortableScope) =>
        if @scope.project.is_backlog_activated
            @data.loadUserStories(@scope).then =>
                @.formatUserStories()
                @scope.$broadcast("wipline:redraw")
        else
            @.uss[sortableScope.status.id] = uss
            @.resortUserStories(sortableScope.status.id).then =>
                @scope.$broadcast("wipline:redraw")

    sortableOnRemove: (us, sortableScope) =>
        _.remove(@.uss[sortableScope.status.id], us)
        @scope.$broadcast("wipline:redraw")


class KanbanUsModalController extends ModalBaseController
    @.$inject = ["$scope", "$rootScope", "$gmOverlay", "$gmFlash", "resource",
                 "$i18next", "selectOptions"]

    constructor: (@scope, @rootScope, @gmOverlay, @gmFlash, @rs, @i18next,
                  @selectOptions) ->
        super(scope)

    initialize: ->
        @scope.type = "create"
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

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    openModal: ->
        @loadProjectTags()
        @scope.form = @scope.context.us
        @scope.formOpened = true

        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        @gmOverlay.open().then =>
            @scope.formOpened = false

    submit: =>
        if @scope.form.id?
            promise = @scope.form.save(false)
        else
            promise = @rs.createUserStory(@scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @gmOverlay.close()
            @scope.form.id = data.id
            @scope.form.ref = data.ref
            @scope.defered.resolve(@scope.form)
            @gmFlash.info(@i18next.t("kanban.user-story-saved"))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise


class KanbanUsController extends TaigaBaseController
    @.$inject = ["$scope", "$rootScope", "$q", "$location"]

    constructor: (@scope, @rootScope, @q, @location) ->
        super(scope)

    updateUsAssignation: (us, id) ->
        us.assigned_to = id || null
        us._moving = true

        onSuccess = -> us._moving = false
        onFail = ->
            us._moving = false
            us.revert()

        us.save().then(onSuccess, onFail)

    openUs: (projectSlug, usRef) ->
        @location.url("/project/#{projectSlug}/user-story/#{usRef}")


moduleDeps = ["taiga.services.resource", "taiga.services.data", "gmModal",
              "taiga.services.model", "i18next", "favico", "gmOverlay",
              "gmFlash"]
module = angular.module("taiga.controllers.kanban", moduleDeps)
module.controller("KanbanController", KanbanController)
module.controller("KanbanUsController", KanbanUsController)
module.controller("KanbanUsModalController", KanbanUsModalController)
