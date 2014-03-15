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


class BacklogController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$routeParams', 'resource', '$data',
                 '$i18next', '$favico']
    constructor: (@scope, @rootScope, @routeParams, @rs, @data, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'backlog'
    getTitle: ->
        @i18next.t("common.backlog")

    initialize: ->
        @rootScope.pageBreadcrumb = [
            ["", ""]
            [@i18next.t("common.backlog"), null]
        ]

        @scope.stats = {}

        @scope.$on "stats:update", (ctx, data) =>
            @reloadStats()

        @scope.$on "milestones:loaded", (ctx, data) =>
            if data.length > 0
                @rootScope.sprintId = data[0].id

        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @data.loadProject(@scope).then =>
                @scope.$emit("stats:update")
                @data.loadUsersAndRoles(@scope)

    reloadStats: ->
        @data.loadProjectStats(@scope).then =>
            closedPoints = @scope.projectStats.closed_points
            totalPoints = @scope.projectStats.total_points
            if totalPoints > 0
                @scope.percentageClosedPoints = (closedPoints * 100) / totalPoints
            else
                @scope.percentageClosedPoints = 0

            @scope.percentageBarCompleted = @scope.percentageClosedPoints

            if @scope.percentageBarCompleted > 100
                @scope.percentageBarCompleted = 99


class BacklogUserStoriesController extends TaigaBaseController
    @.$inject = ['$scope', '$rootScope', '$q', 'resource', '$data', '$modal',
                 '$location', 'SelectedTags']
    constructor: (@scope, @rootScope, @q, @rs, @data, @modal, @location, @SelectedTags) ->
        super(scope)

    initialize: ->
        # Local scope variables
        @scope.selectedUserStories = null
        @scope.selectedStoryPoints = 9

        @scope.filtersOpened = if @SelectedTags(@rootScope.projectId).backlog.isEmpty() then false else true
        @scope.showTags = false

        @scope.$on("points:loaded", @loadUserStories)
        @scope.$on("userstory-form:create", @loadUserStories)

        @scope.$on "milestones:loaded", (ctx, data) =>
            @scope.milestones = data

    calculateStats: ->
        @scope.$emit("stats:update")

    generateTagList: ->
        tagsDict = {}
        tags = []

        for us in @scope.unassignedUs
            for tag in us.tags
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        for key, val of tagsDict
            tag = {name:key, count:val}
            tag.selected = true if @SelectedTags(@rootScope.projectId).backlog.fetch(tag)
            tags.push(tag)

        @scope.tags = tags

    selectedTags: ->
        return @SelectedTags(@rootScope.projectId).backlog.values()

    filterUsBySelectedTags: ->
        selectedTagNames = @SelectedTags(@rootScope.projectId).backlog.names()
        if selectedTagNames.length > 0
            for item in @scope.unassignedUs
                if _.intersection(selectedTagNames, item.tags).length == 0
                    item.__hidden = true
                else
                    item.__hidden = false
        else
            item.__hidden = false for item in @scope.unassignedUs

    resortUserStories: ->
        saveChangedOrder = =>
            for item, index in @scope.unassignedUs
                item.order = index

            modifiedUs = _.filter(@scope.unassignedUs, (x) -> x.isModified())
            bulkData = _.map(@scope.unassignedUs, (value, index) -> [value.id, index])

            for item in modifiedUs
                item._moving = true

            promise = @rs.updateBulkUserStoriesOrder(@scope.projectId, bulkData)
            promise = promise.then ->
                for us in modifiedUs
                    us.markSaved()
                    us._moving = false

            return promise

        @q.when(saveChangedOrder())
          .then(@calculateStats)

    loadUserStories: =>
        @data.loadUnassignedUserStories(@scope).then =>
            @generateTagList()
            @filterUsBySelectedTags()
            @calculateStats()

    calculateStoryPoints: (selectedUserStories) ->
        total = 0

        if not selectedUserStories?
            return 0

        for us in selectedUserStories
            for roleId, pointId of us.points
                pointsValue = @scope.constants.points[pointId].value
                if pointsValue is null
                    pointsValue = 0
                total += pointsValue

        return total

    getSelectedUserStories: ->
        selected = _.filter(@scope.unassignedUs, "selected")
        if selected.length == 0
            return null
        return selected

    getUnselectedUserStories: ->
        selected = _.reject(@scope.unassignedUs, "selected")
        if selected.length == 0
            return null
        return selected

    moveSelectedUserStoriesToCurrentSprint: ->
        if @scope.milestones.length == 0
            return

        milestone = @scope.milestones[0]

        selected = @getSelectedUserStories()
        unselected = @getUnselectedUserStories()

        for us in selected
            milestone.user_stories.push(us)
            us.milestone = milestone.id
            us.save()

        @scope.unassignedUs = unselected

    changeUserStoriesSelection: ->
        selected = @scope.selectedUserStories = @getSelectedUserStories()
        @scope.selectedStoryPoints = @calculateStoryPoints(selected)

    refreshBacklog: ->
        @scope.refreshing = true
        @loadUserStories().then ->
            @scope.refreshing = false

    openUserStory: (projectSlug, usRef) ->
        @location.url("/project/#{projectSlug}/user-story/#{usRef}")

    getUserStoryQueryParams: ->
        {milestone: 'null', tags: @SelectedTags(@rootScope.projectId).backlog.join()}

    initializeUsForm: (us) ->
        result = {}
        if us?
            result = us
        else
            points = {}
            for role in @scope.constants.computableRolesList
                points[role.id] = @scope.project.default_points
            result['points'] = points
            result['project'] = @scope.projectId
            result['status'] = @scope.project.default_us_status

        return result

    openBulkUserStoriesForm: ->
        promise = @modal.open("bulk-user-stories-form", {})
        promise.then =>
            @loadUserStories()

    openCreateUserStoryForm: ->
        promise = @modal.open("user-story-form", {"us": @initializeUsForm(), "type": "create"})
        promise.then =>
            @loadUserStories()

    openEditUserStoryForm: (us) ->
        promise = @modal.open("user-story-form", {"us": @initializeUsForm(us), "type": "edit"})
        promise.then =>
            @loadUserStories()

    removeUs: (us) ->
        us.remove().then =>
            index = @scope.unassignedUs.indexOf(us)
            @scope.unassignedUs.splice(index, 1)

            @calculateStats()
            @generateTagList()
            @filterUsBySelectedTags()

    saveUsPoints: (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        us._moving = true
        promise = us.save()
        promise.then =>
            us._moving = false
            @calculateStats()
            @scope.$broadcast("points:changed")

        promise.then null, (data, status) ->
            us._moving = false
            us.revert()

    saveUsStatus: (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) ->
            data._moving = false

    # User Story Filters
    toggleTag: (tag) ->
        if tag.selected
            tag.selected = false
            @SelectedTags(@rootScope.projectId).backlog.remove(tag)
        else
            tag.selected = true
            @SelectedTags(@rootScope.projectId).backlog.store(tag)

        @filterUsBySelectedTags()

    sortableOnAdd: (us, index) ->
        us.milestone = null
        us.save().then =>
            @scope.unassignedUs.splice(index, 0, us)
            @resortUserStories()

    sortableOnUpdate: (uss) ->
        @scope.unassignedUs = uss
        @resortUserStories()

    sortableOnRemove: (us) ->
        _.remove(@scope.unassignedUs, us)
        selected = @scope.selectedUserStories = @getSelectedUserStories()
        @scope.selectedStoryPoints = @calculateStoryPoints(selected)


class BacklogUserStoryModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash',
                 '$i18next']
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next) ->
        super(scope)

    initialize: ->
        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @tagsSelectOptionsShowColorizedTags
            containerCssClass: "tags-selector"
        }
        super()

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    openModal: ->
        @loadProjectTags()
        @scope.formOpened = true
        @scope.form = @scope.context.us

        # TODO: More general solution must be found.
        # This hack is used to take care on save user story as PATCH requests
        # and save correctly the multiple deep levels attributes
        usCopy = _.cloneDeep(@scope.context.us)
        @scope.$watch('form.points', =>
            if JSON.stringify(@scope.form.points) != JSON.stringify(usCopy.points)
                @scope.form.points = _.clone(@scope.form.points)
        , true)
        @scope.$broadcast("checksley:reset")
        @scope.$broadcast("wiki:clean-previews")

        @gmOverlay.open().then =>
            @scope.formOpened = false

    # Debounced Method (see debounceMethods method)
    submit: =>
        if @scope.form.id?
            promise = @scope.form.save()
        else
            promise = @rs.createUserStory(@scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @gmOverlay.close()
            @scope.defered.resolve()
            @gmFlash.info(@i18next.t('backlog.user-story-saved'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    tagsSelectOptionsShowColorizedTags: (option, container) ->
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


class BacklogBulkUserStoriesModalController extends ModalBaseController
    @.$inject = ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash',
                 '$i18next']
    constructor: (@scope, @rootScope, @gmOverlay, @rs, @gmFlash, @i18next) ->
        super(scope)

    openModal: ->
        @scope.formOpened = true
        @scope.$broadcast("checksley:reset")

        @gmOverlay.open().then =>
            @scope.formOpened = false

    # Debounced Method (see debounceMethods method)
    submit: =>
        promise = @rs.createBulkUserStories(@scope.projectId, @scope.form)
        @scope.$emit("spinner:start")

        promise.then (data) =>
            @scope.$emit("spinner:stop")
            @closeModal()
            @gmOverlay.close()
            @scope.defered.resolve()
            @gmFlash.info(@i18next.t('backlog.bulk-user-stories-created', { count: data.data.length }))
            @scope.form = {}

        promise.then null, (data) =>
            @scope.checksleyErrors = data


class BacklogMilestonesController extends TaigaBaseController
    @.$inject = ['$scope', '$rootScope', 'resource', '$gmFlash', '$i18next',
                 '$location']
    constructor: (@scope, @rootScope, @rs, @gmFlash, @i18next, @location) ->
        super(scope)

    debounceMethods: ->
        sprintSubmit = @sprintSubmit
        @sprintSubmit = gm.utils.safeDebounced @scope, 500, sprintSubmit

    initialize: ->
        @debounceMethods()
        # Local scope variables
        @scope.sprintFormOpened = false

        @scope.$on "points:loaded", =>
            @rs.getMilestones(@rootScope.projectId).then (data) =>
                # HACK: because django-filter does not works properly
                # @scope.milestones = data
                @scope.milestones = _.filter data, (item) =>
                    item.project == @rootScope.projectId

                @calculateStats()
                @rootScope.$broadcast("milestones:loaded", @scope.milestones)

    calculateStats: ->
        @scope.$emit("stats:update")

    openUserStory: (projectSlug, usRef) ->
        @location.url("/project/#{projectSlug}/user-story/#{usRef}")

    # Debounced Method (see debounceMethods method)
    sprintSubmit: =>
        if @scope.form.save is undefined
            promise = @rs.createMilestone(@scope.projectId, @scope.form)

            promise.then (milestone) =>
                @scope.milestones.unshift(milestone)
                # Clear the current form after creating
                # of new sprint is completed
                @scope.form = {}
                @scope.sprintFormOpened = false
                # Update the sprintId value for correct
                # linking of dashboard menu item to the
                # last created milestone
                @rootScope.sprintId = milestone.id
                # Show a success message
                @gmFlash.info(@i18next.t('backlog.sprint-saved'))

            promise.then null, (data) =>
                @scope.checksleyErrors = data
        else
            promise = @scope.form.save()

            promise.then (data) =>
                @scope.form = {}
                @scope.sprintFormOpened = false
                @gmFlash.info(@i18next.t('backlog.sprint-saved'))

            promise.then null, (data) =>
                @scope.checksleyErrors = data


class BacklogMilestoneController extends TaigaBaseController
    @.$inject = ['$scope', '$q', 'resource', '$gmFlash', '$i18next']
    constructor: (@scope, @q, @rs, @gmFlash, @i18next) ->
        super(scope)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @scope.editFormOpened = false
        @scope.viewUSs = not @scope.ml.closed
        @calculateStats()

    calculateTotalPoints: (us) ->
        total = 0
        for roleId, pointId of us.points
            total += @scope.constants.points[pointId].value
        return total

    calculateStats: ->
        total = 0
        closed = 0

        for us in @scope.ml.user_stories
            points = @calculateTotalPoints(us)
            total += points
            closed += points if us.is_closed

        @scope.stats =
            total: total
            closed: closed
            percentage: if total then ((closed * 100) / total).toFixed(1) else 0.0

    normalizeMilestones: =>
        saveChangedMilestone = =>
            console.log "saveChangedMilestone"
            for item, index in @scope.ml.user_stories
                item.milestone = @scope.ml.id

            filtered = _.filter(@scope.ml.user_stories, (x) -> x.isModified())
            pchain = _.map(filtered, (x) -> x.save())

            return @q.all(pchain)

        saveChangedOrder = =>
            console.log "saveChangedOrder"
            for item, index in @scope.ml.user_stories
                item.order = index
                if item.isModified()
                    item._moving = true

            bulkData = _.map(@scope.ml.user_stories, (value, index) -> [value.id, index])
            return @rs.updateBulkUserStoriesOrder(@scope.projectId, bulkData)

        markAsSaved = =>
            for item in @scope.ml.user_stories
                item._moving = false
                item.markSaved()

            return null

        @q.when(saveChangedMilestone())
          .then(saveChangedOrder)
          .then(markAsSaved)
          .then(@calculateStats)

    showEditForm: ->
        @scope.editFormOpened = true

    toggleViewUSs: ->
        @scope.viewUSs = not @scope.viewUSs

    # Debounced Method (see debounceMethods method)
    submit: =>
        promise = @scope.ml.save()

        promise.then (data) =>
            @scope.editFormOpened = false
            @gmFlash.info(@i18next.t('backlog.sprint-modified'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    closeEditForm: ->
        @scope.editFormOpened = false
        @scope.ml.refresh()

    sortableOnAdd: (us, index) ->
        us.milestone = @scope.ml.id
        us.save().then =>
            @scope.ml.user_stories.splice(index, 0, us)
            @normalizeMilestones()

    sortableOnUpdate: (uss) ->
        @scope.ml.user_stories = uss
        @normalizeMilestones()

    sortableOnRemove: (us) ->
        _.remove(@scope.ml.user_stories, us)


module = angular.module("taiga.controllers.backlog", [])
module.controller('BacklogController', BacklogController)
module.controller('BacklogUserStoriesController', BacklogUserStoriesController)
module.controller('BacklogUserStoryModalController', BacklogUserStoryModalController)
module.controller('BacklogBulkUserStoriesModalController', BacklogBulkUserStoriesModalController)
module.controller('BacklogMilestonesController', BacklogMilestonesController)
module.controller('BacklogMilestoneController', BacklogMilestoneController)
