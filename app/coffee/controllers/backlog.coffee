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


BacklogController = ($scope, $rootScope, $routeParams, rs, $data) ->
    # Global Scope Variables
    $rootScope.pageSection = 'backlog'
    $rootScope.pageBreadcrumb = [
        ["", ""]
        ["Backlog", null]
    ]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.stats = {}

    $scope.$on "stats:update", (ctx, data) ->
        $data.loadProjectStats($scope).then ->
            if $scope.projectStats.total_points > 0
                $scope.percentageClosedPoints = ($scope.projectStats.closed_points * 100) / $scope.projectStats.total_points
            else
                $scope.percentageClosedPoints = 0

    $scope.$on "milestones:loaded", (ctx, data) ->
        if data.length > 0
            $rootScope.sprintId = data[0].id

    $data.loadProject($scope).then ->
        $scope.$emit("stats:update")
        $data.loadUsersAndRoles($scope)


BacklogUserStoriesController = ($scope, $rootScope, $q, rs, $data, $modal) ->
    calculateStats = ->
        $scope.$emit("stats:update")

    generateTagList = ->
        tagsDict = {}
        tags = []

        for us in $scope.unassingedUs
            for tag in us.tags
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        for key, val of tagsDict
            tags.push({name:key, count:val})

        $scope.tags = tags

     filterUsBySelectedTags = ->
        selectedTags = _($scope.tags)
                             .filter("selected")
                             .map("name")
                             .value()

        if selectedTags.length > 0
            for item in $scope.unassingedUs
                itemTags = item.tags
                interSection = _.intersection(selectedTags, itemTags)

                if interSection.length == 0
                    item.__hidden = true
                else
                    item.__hidden = false

        else
            item.__hidden = false for item in $scope.unassingedUs

    resortUserStories = ->
        # Normalize user stories array
        _.each $scope.unassingedUs, (item, index) ->
            item.order = index
            item.milestone = null

        for item, index in $scope.unassingedUs
            item.order = index
            item.milestone = null

        # Sort again
        $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order")

        # Calculte new stats
        calculateStats()

        # TODO: defer each save.
        for item in $scope.unassingedUs
            item.save() if item.isModified()

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
        selected = _.filter($scope.unassingedUs, "selected")
        if selected.length == 0
            return null
        return selected

    getUnselectedUserStories = ->
        selected = _.reject($scope.unassingedUs, "selected")
        if selected.length == 0
            return null
        return selected

    # Local scope variables
    $scope.selectedUserStories = null
    $scope.selectedStoryPoints = 9

    $scope.filtersOpened = false
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

        $scope.unassingedUs = unselected

    $scope.changeUserStoriesSelection = ->
        selected = $scope.selectedUserStories = getSelectedUserStories()
        $scope.selectedStoryPoints = calculateStoryPoints(selected)

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

    $scope.openCreateUserStoryForm = ->
        promise = $modal.open("user-story-form", {"us": initializeUsForm()})
        promise.then ->
            loadUserStories()

    $scope.openEditUserStoryForm = (us) ->
        promise = $modal.open("user-story-form", {"us": initializeUsForm(us)})
        promise.then ->
            loadUserStories()

    $scope.removeUs = (us) ->
        us.remove().then ->
            index = $scope.unassingedUs.indexOf(us)
            $scope.unassingedUs.splice(index, 1)

            calculateStats()
            generateTagList()
            filterUsBySelectedTags()

    $scope.saveUsPoints = (us, role, ref) ->
        points = _.clone(us.points)
        points[role.id] = ref

        us.points = points

        promise = us.save()
        promise.then ->
            calculateStats()
            $scope.$broadcast("points:changed")

        promise.then null, (data, status) ->
            us.revert()

    # User Story Filters
    $scope.selectTag = (tag) ->
        if tag.selected
            tag.selected = false
        else
            tag.selected = true

        filterUsBySelectedTags()

    # Signal Handlign
    $scope.$on("sortable:changed", resortUserStories)
    $scope.$on("sortable:changed", ->
        selected = $scope.selectedUserStories = getSelectedUserStories()
        $scope.selectedStoryPoints = calculateStoryPoints(selected)
    )


BacklogUserStoryModalController = ($scope, $rootScope, $gmOverlay, rs, $gmFlash) ->
    $scope.formOpened = false

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
        $scope.$broadcast("checksley:reset")

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
            promise = $scope.form.save(false)
        else
            promise = rs.createUserStory($scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            $scope.$emit("spinner:stop")
            closeModal()
            $scope.overlay.close()
            $scope.defered.resolve()
            $gmFlash.info("The user story has been saved")

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

BacklogMilestonesController = ($scope, $rootScope, rs, $gmFlash) ->
    # Local scope variables
    $scope.sprintFormOpened = false

    calculateStats = ->
        $scope.$emit("stats:update")

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
                $gmFlash.info("The sprint has been saved")

            promise.then null, (data) ->
                $scope.checksleyErrors = data
        else
            promise = $scope.form.save()

            promise.then (data) ->
                $scope.form = {}
                $scope.sprintFormOpened = false
                $gmFlash.info("The sprint has been saved")

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


BacklogMilestoneController = ($scope, rs, $gmFlash) ->
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
        _.each $scope.ml.user_stories, (item, index) ->
            item.milestone = $scope.ml.id

        # Calculte new stats
        calculateStats()

        _.each $scope.ml.user_stories, (item) ->
            if item.isModified()
                item.save()

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
            $gmFlash.info("The sprint has been modified")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.closeEditForm = ->
        $scope.editFormOpened = false
        $scope.ml.refresh()

    calculateStats()
    $scope.$on("sortable:changed", normalizeMilestones)


module = angular.module("greenmine.controllers.backlog", [])
module.controller('BacklogMilestoneController', ['$scope', 'resource', '$gmFlash', BacklogMilestoneController])
module.controller('BacklogMilestonesController', ['$scope', '$rootScope', 'resource', '$gmFlash', BacklogMilestonesController])
module.controller('BacklogUserStoriesController', ['$scope', '$rootScope', '$q', 'resource', '$data', '$modal', BacklogUserStoriesController])
module.controller('BacklogController', ['$scope', '$rootScope', '$routeParams', 'resource', '$data', BacklogController])
module.controller('BacklogUserStoryModalController', ['$scope', '$rootScope', '$gmOverlay', 'resource', '$gmFlash', BacklogUserStoryModalController])
