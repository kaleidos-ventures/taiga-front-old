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


BacklogController = ($scope, $rootScope, $routeParams, rs, $data, $i18next, $favico, SelectedTags) ->
    $favico.reset()
    # Global Scope Variables
    $rootScope.pageTitle = $i18next.t("common.backlog")
    $rootScope.pageSection = 'backlog'
    $rootScope.pageBreadcrumb = [
        ["", ""]
        [$i18next.t("common.backlog"), null]
    ]

    $scope.stats = {}

    $scope.$on "stats:update", (ctx, data) ->
        $data.loadProjectStats($scope).then ->
            if $scope.projectStats.total_points > 0
                $scope.percentageClosedPoints = ($scope.projectStats.closed_points * 100) / $scope.projectStats.total_points
            else
                $scope.percentageClosedPoints = 0

            $scope.percentageBarCompleted = $scope.percentageClosedPoints

            if $scope.percentageBarCompleted > 100
                $scope.percentageBarCompleted = 99

    $scope.$on "milestones:loaded", (ctx, data) ->
        if data.length > 0
            $rootScope.sprintId = data[0].id

    rs.resolve(pslug: $routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $data.loadProject($scope).then ->
            $scope.$emit("stats:update")
            $data.loadUsersAndRoles($scope)
    return


BacklogUserStoriesController = ($scope, $rootScope, $q, rs, $data, $modal, $location, SelectedTags) ->
    calculateStats = ->
        $scope.$emit("stats:update")

    generateTagList = ->
        tagsDict = {}
        tags = []

        for us in $scope.unassignedUs
            for tag in us.tags
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        for key, val of tagsDict
            tag = {name:key, count:val}
            tag.selected = true if SelectedTags($rootScope.projectId).backlog.fetch(tag)
            tags.push(tag)

        $scope.tags = tags

    $scope.selectedTags = ->
        return SelectedTags($rootScope.projectId).backlog.values()

    filterUsBySelectedTags = ->
       selectedTagNames = SelectedTags($rootScope.projectId).backlog.names()
       if selectedTagNames.length > 0
           for item in $scope.unassignedUs
               if _.intersection(selectedTagNames, item.tags).length == 0
                   item.__hidden = true
               else
                   item.__hidden = false
       else
           item.__hidden = false for item in $scope.unassignedUs

    resortUserStories = ->
        saveChangedOrder = ->
            for item, index in $scope.unassignedUs
                item.order = index

            modifiedUs = _.filter($scope.unassignedUs, (x) -> x.isModified())
            bulkData = _.map($scope.unassignedUs, (value, index) -> [value.id, index])

            for item in modifiedUs
                item._moving = true

            promise = rs.updateBulkUserStoriesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for us in modifiedUs
                    us.markSaved()
                    us._moving = false

            return promise

        $q.when(saveChangedOrder())
          .then(calculateStats)

    loadUserStories = ->
        $data.loadUnassignedUserStories($scope).then ->
            generateTagList()
            filterUsBySelectedTags()
            calculateStats()

    calculateStoryPoints = (selectedUserStories) ->
        total = 0

        if not selectedUserStories?
            return 0

        for us in selectedUserStories
            for roleId, pointId of us.points
                pointsValue = $scope.constants.points[pointId].value
                if pointsValue is null
                    pointsValue = 0
                total += pointsValue

        return total

    getSelectedUserStories = ->
        selected = _.filter($scope.unassignedUs, "selected")
        if selected.length == 0
            return null
        return selected

    getUnselectedUserStories = ->
        selected = _.reject($scope.unassignedUs, "selected")
        if selected.length == 0
            return null
        return selected

    # Local scope variables
    $scope.selectedUserStories = null
    $scope.selectedStoryPoints = 9

    $scope.filtersOpened = if SelectedTags($rootScope.projectId).backlog.isEmpty() then false else true
    $scope.showTags = false

    $scope.moveSelectedUserStoriesToCurrentSprint = ->
        if $scope.milestones.length == 0
            return

        milestone = $scope.milestones[0]

        selected = getSelectedUserStories()
        unselected = getUnselectedUserStories()

        for us in selected
            milestone.user_stories.push(us)
            us.milestone = milestone.id
            us.save()

        $scope.unassignedUs = unselected

    $scope.changeUserStoriesSelection = ->
        selected = $scope.selectedUserStories = getSelectedUserStories()
        $scope.selectedStoryPoints = calculateStoryPoints(selected)

    $scope.refreshBacklog = ->
        $scope.refreshing = true
        loadUserStories().then ->
            $scope.refreshing = false

    $scope.openUserStory = (projectSlug, usRef) ->
        $location.url("/project/#{projectSlug}/user-story/#{usRef}")

    $scope.getUserStoryQueryParams = -> {milestone: 'null', tags: SelectedTags($rootScope.projectId).backlog.join()}

    $scope.$on("points:loaded", loadUserStories)
    $scope.$on("userstory-form:create", loadUserStories)

    $scope.$on "milestones:loaded", (ctx, data) ->
        $scope.milestones = data

    initializeUsForm = (us) ->
        result = {}
        if us?
            result = us
        else
            points = {}
            for role in $scope.constants.computableRolesList
                points[role.id] = $scope.project.default_points
            result['points'] = points
            result['project'] = $scope.projectId
            result['status'] = $scope.project.default_us_status

        return result

    $scope.openBulkUserStoriesForm = ->
        promise = $modal.open("bulk-user-stories-form", {})
        promise.then ->
            loadUserStories()

    $scope.openCreateUserStoryForm = ->
        promise = $modal.open("user-story-form", {"us": initializeUsForm(), "type": "create"})
        promise.then ->
            loadUserStories()

    $scope.openEditUserStoryForm = (us) ->
        promise = $modal.open("user-story-form", {"us": initializeUsForm(us), "type": "edit"})
        promise.then ->
            loadUserStories()

    $scope.removeUs = (us) ->
        us.remove().then ->
            index = $scope.unassignedUs.indexOf(us)
            $scope.unassignedUs.splice(index, 1)

            calculateStats()
            generateTagList()
            filterUsBySelectedTags()

    $scope.saveUsPoints = (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        us._moving = true
        promise = us.save()
        promise.then ->
            us._moving = false
            calculateStats()
            $scope.$broadcast("points:changed")

        promise.then null, (data, status) ->
            us._moving = false
            us.revert()

    $scope.saveUsStatus = (us, id) ->
        us.status = id
        us._moving = true
        us.save().then (data) ->
            data._moving = false

    # User Story Filters
    $scope.toggleTag = (tag) ->
        if tag.selected
            tag.selected = false
            SelectedTags($rootScope.projectId).backlog.remove(tag)
        else
            tag.selected = true
            SelectedTags($rootScope.projectId).backlog.store(tag)

        filterUsBySelectedTags()

    $scope.sortableOnAdd = (us, index) ->
        us.milestone = null
        us.save().then ->
            $scope.unassignedUs.splice(index, 0, us)
            resortUserStories()

    $scope.sortableOnUpdate = (uss) ->
        $scope.unassignedUs = uss
        resortUserStories()

    $scope.sortableOnRemove = (us) ->
        _.remove($scope.unassignedUs, us)
        selected = $scope.selectedUserStories = getSelectedUserStories()
        $scope.selectedStoryPoints = calculateStoryPoints(selected)

BacklogUserStoryModalController = ($scope, $rootScope, $gmOverlay, rs, $gmFlash, $i18next) ->
    $scope.formOpened = false
    $scope.bulkFormOpened = false

    # Load data
    $scope.defered = null
    $scope.context = null

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    openModal = ->
        loadProjectTags()
        $scope.formOpened = true
        $scope.form = $scope.context.us

        # TODO: More general solution must be found.
        # This hack is used to take care on save user story as PATCH requests
        # and save correctly the multiple deep levels attributes
        usCopy = _.cloneDeep($scope.context.us)
        $scope.$watch('form.points', ->
            if JSON.stringify($scope.form.points) != JSON.stringify(usCopy.points)
                $scope.form.points = _.clone($scope.form.points)
        , true)
        $scope.$broadcast("checksley:reset")
        $scope.$broadcast("wiki:clean-previews")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

    closeModal = ->
        $scope.formOpened = false

    @.initialize = (dfr, ctx) ->
        $scope.defered = dfr
        $scope.context = ctx
        openModal()

    @.delete = ->
        closeModal()
        $scope.form = form
        $scope.formOpened = true

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        if $scope.form.id?
            promise = $scope.form.save()
        else
            promise = rs.createUserStory($scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            $scope.$emit("spinner:stop")
            closeModal()
            $scope.overlay.close()
            $scope.defered.resolve()
            $gmFlash.info($i18next.t('backlog.user-story-saved'))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.form.id?
            $scope.form.revert()
        else
            $scope.form = {}

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

    return

BacklogBulkUserStoriesModalController = ($scope, $rootScope, $gmOverlay, rs, $gmFlash, $i18next) ->
    $scope.bulkFormOpened = false

    # Load data
    $scope.defered = null
    $scope.context = null

    openModal = ->
        $scope.bulkFormOpened = true
        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.bulkFormOpened = false

    closeModal = ->
        $scope.bulkFormOpened = false

    @.initialize = (dfr, ctx) ->
        $scope.defered = dfr
        $scope.context = ctx
        openModal()

    @.delete = ->
        closeModal()
        $scope.form = form
        $scope.bulkFormOpened = true

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        promise = rs.createBulkUserStories($scope.projectId, $scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            $scope.$emit("spinner:stop")
            closeModal()
            $scope.overlay.close()
            $scope.defered.resolve()
            $gmFlash.info($i18next.t('backlog.bulk-user-stories-created', { count: data.data.length }))
            $scope.form = {}

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.bulkFormOpened = false
        $scope.overlay.close()
        $scope.form = {}

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

    return


BacklogMilestonesController = ($scope, $rootScope, rs, $gmFlash, $i18next, $location) ->
    # Local scope variables
    $scope.sprintFormOpened = false

    calculateStats = ->
        $scope.$emit("stats:update")

    $scope.openUserStory = (projectSlug, usRef)->
        $location.url("/project/#{projectSlug}/user-story/#{usRef}")

    $scope.sprintSubmit = gm.utils.safeDebounced $scope, 400, ->
        if $scope.form.save is undefined
            promise = rs.createMilestone($scope.projectId, $scope.form)

            promise.then (milestone) ->
                $scope.milestones.unshift(milestone)
                # Clear the current form after creating
                # of new sprint is completed
                $scope.form = {}
                $scope.sprintFormOpened = false
                # Update the sprintId value for correct
                # linking of dashboard menu item to the
                # last created milestone
                $rootScope.sprintId = milestone.id
                # Show a success message
                $gmFlash.info($i18next.t('backlog.sprint-saved'))

            promise.then null, (data) ->
                $scope.checksleyErrors = data
        else
            promise = $scope.form.save()

            promise.then (data) ->
                $scope.form = {}
                $scope.sprintFormOpened = false
                $gmFlash.info($i18next.t('backlog.sprint-saved'))

            promise.then null, (data) ->
                $scope.checksleyErrors = data

    $scope.$on "points:loaded", ->
        rs.getMilestones($rootScope.projectId).then (data) ->
            # HACK: because django-filter does not works properly
            # $scope.milestones = data
            $scope.milestones = _.filter data, (item) ->
                item.project == $rootScope.projectId

            calculateStats()
            $rootScope.$broadcast("milestones:loaded", $scope.milestones)

    return


BacklogMilestoneController = ($scope, $q, rs, $gmFlash, $i18next) ->
    calculateTotalPoints = (us) ->
        total = 0
        for roleId, pointId of us.points
            total += $scope.constants.points[pointId].value
        return total

    calculateStats = ->
        total = 0
        closed = 0

        for us in $scope.ml.user_stories
            points = calculateTotalPoints(us)
            total += points
            closed += points if us.is_closed

        $scope.stats =
            total: total
            closed: closed
            percentage: if total then ((closed * 100) / total).toFixed(1) else 0.0

    normalizeMilestones = ->
        saveChangedMilestone = ->
            console.log "saveChangedMilestone"
            for item, index in $scope.ml.user_stories
                item.milestone = $scope.ml.id

            filtered = _.filter($scope.ml.user_stories, (x) -> x.isModified())
            pchain = _.map(filtered, (x) -> x.save())

            return $q.all(pchain)

        saveChangedOrder = ->
            console.log "saveChangedOrder"
            for item, index in $scope.ml.user_stories
                item.order = index
                if item.isModified()
                    item._moving = true

            bulkData = _.map($scope.ml.user_stories, (value, index) -> [value.id, index])
            return rs.updateBulkUserStoriesOrder($scope.projectId, bulkData)

        markAsSaved = ->
            for item in $scope.ml.user_stories
                item._moving = false
                item.markSaved()

            return null

        $q.when(saveChangedMilestone())
          .then(saveChangedOrder)
          .then(markAsSaved)
          .then(calculateStats)

    $scope.editFormOpened = false
    $scope.viewUSs = not $scope.ml.closed

    $scope.showEditForm = () ->
        $scope.editFormOpened = true

    $scope.toggleViewUSs = ->
        $scope.viewUSs = not $scope.viewUSs

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        promise = $scope.ml.save()

        promise.then (data) ->
            $scope.editFormOpened = false
            $gmFlash.info($i18next.t('backlog.sprint-modified'))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.closeEditForm = ->
        $scope.editFormOpened = false
        $scope.ml.refresh()

    calculateStats()

    $scope.sortableOnAdd = (us, index) ->
        us.milestone = $scope.ml.id
        us.save().then ->
            $scope.ml.user_stories.splice(index, 0, us)
            normalizeMilestones()

    $scope.sortableOnUpdate = (uss) ->
        $scope.ml.user_stories = uss
        normalizeMilestones()

    $scope.sortableOnRemove = (us) ->
        _.remove($scope.ml.user_stories, us)

    return


module = angular.module("taiga.controllers.backlog", [])
module.controller('BacklogMilestoneController', ['$scope', '$q', 'resource', '$gmFlash', '$i18next',
                                                 BacklogMilestoneController])
module.controller('BacklogMilestonesController', ['$scope', '$rootScope', 'resource', '$gmFlash', '$i18next',
                                                  '$location', BacklogMilestonesController])
module.controller('BacklogUserStoriesController', ['$scope', '$rootScope', '$q', 'resource', '$data', '$modal',
                                                   '$location', 'SelectedTags', BacklogUserStoriesController])
module.controller('BacklogController', ['$scope', '$rootScope', '$routeParams', 'resource', '$data', '$i18next',
                                        '$favico', 'SelectedTags', BacklogController])
module.controller('BacklogUserStoryModalController', ['$scope', '$rootScope', '$gmOverlay', 'resource',
                                                      '$gmFlash', '$i18next', BacklogUserStoryModalController])
module.controller('BacklogBulkUserStoriesModalController', ['$scope', '$rootScope', '$gmOverlay', 'resource',
                                                            '$gmFlash', '$i18next',
                                                            BacklogBulkUserStoriesModalController])
