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
    $rootScope.pageBreadcrumb = ["", "Backlog"]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.stats = {}

    $scope.$on "stats:update", (ctx, data) ->
        if data.notAssignedPoints
            $scope.stats.notAssignedPoints = data.notAssignedPoints

        if data.completedPoints
            $scope.stats.completedPoints = data.completedPoints

        if data.assignedPoints
            $scope.stats.assignedPoints = data.assignedPoints

        total = ($scope.stats.notAssignedPoints || 0) +
                         ($scope.stats.assignedPoints || 0)

        completed = $scope.stats.completedPoints || 0

        $scope.stats.completedPercentage = ((completed * 100) / total).toFixed(1)
        $scope.stats.totalPoints = total

    $scope.$on "milestones:loaded", (ctx, data) ->
        if data.length > 0
            $rootScope.sprintId = data[0].id

    $data.loadProject($scope)
    $data.loadCommonConstants($scope).then ->
        $data.loadUserStoryPoints($scope)


BacklogUserStoriesController = ($scope, $rootScope, $q, rs, $data, $modal) ->
    # Local scope variables
    $scope.filtersOpened = false
    $scope.showTags = false

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.pointsByOrder, $scope.roles)
        total = 0

        for us in $scope.unassingedUs
            total += pointIdToOrder(us.points)

        $scope.$emit("stats:update", {"notAssignedPoints": total})

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

    $scope.$on("points:loaded", loadUserStories)
    $scope.$on("userstory-form:create", loadUserStories)

    $scope.openCreateUserStoryForm = ->
        promise = $modal.open("user-story-form", {"us": {us:[], points:{}, project:$scope.projectId}})
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


BacklogUserStoryModalController = ($scope, $rootScope, $gmOverlay, rs) ->
    $scope.formOpened = false

    # Load data
    promise = rs.getUsStatuses($scope.projectId)
    promise.then (result) ->
        $scope.usstatuses = result

    $scope.defered = null
    $scope.context = null

    openModal = ->
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

    $scope.submit = ->
        $scope.overlay.close()
        rs.createUserStory($scope.form).then ->
            closeModal()
            $scope.defered.resolve()

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.type == "create"
            $scope.form = {}
        else
            $scope.form.revert()


BacklogMilestonesController = ($scope, $rootScope, rs) ->
    # Local scope variables
    $scope.sprintFormOpened = false
    $scope.sprintEditFormOpened = {}

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.pointsByOrder, $scope.roles)
        assigned = 0
        completed = 0

        for ml in $scope.milestones
            for us in ml.user_stories
                assigned += pointIdToOrder(us.points)
                if us.is_closed
                    completed += pointIdToOrder(us.points)

        $scope.$emit("stats:update", {
            "assignedPoints": assigned,
            "completedPoints": completed
        })

    $scope.showEditForm = (id) ->
        $scope.sprintEditFormOpened[id] = true

    $scope.sprintEditSubmit = (milestone) ->
        milestone.save().then ->
            $scope.sprintEditFormOpened[milestone.id] = false

    $scope.closeSprintEditForm = (milestone) ->
        $scope.sprintEditFormOpened[milestone.id] = false
        milestone.revert()

    $scope.sprintSubmit = ->
        if $scope.form.save is undefined
            rs.createMilestone($scope.projectId, $scope.form).then (milestone) ->
                $scope.milestones.unshift(milestone)

                # Clear the current form after creating
                # of new sprint is completed
                $scope.form = {}
                $scope.sprintFormOpened = false

                # Update the sprintId value for correct
                # linking of dashboard menu item to the
                # last created milestone
                $rootScope.sprintId = milestone.id

        else
            $scope.form.save().then ->
                $scope.form = {}
                $scope.sprintFormOpened = false

    $scope.$on "points:loaded", ->
        rs.getMilestones($rootScope.projectId).then (data) ->
            # HACK: because django-filter does not works properly
            # $scope.milestones = data
            $scope.milestones = _.filter data, (item) ->
                item.project == $rootScope.projectId

            calculateStats()
            $scope.$emit("milestones:loaded", $scope.milestones)



BacklogMilestoneController = ($scope, rs) ->
    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.pointsByOrder, $scope.roles)
        total = 0
        completed = 0

        _.each $scope.ml.user_stories, (us) ->
            total += pointIdToOrder(us.points)

            if us.is_closed
                completed += pointIdToOrder(us.points)

        $scope.stats =
            total: total
            completed: completed
            percentage: ((completed * 100) / total).toFixed(1)

    normalizeMilestones = ->
        _.each $scope.ml.user_stories, (item, index) ->
            item.milestone = $scope.ml.id

        # Calculte new stats
        calculateStats()

        _.each $scope.ml.user_stories, (item) ->
            if item.isModified()
                item.save()

    calculateStats()
    $scope.$on("sortable:changed", normalizeMilestones)


module = angular.module("greenmine.controllers.backlog", [])
module.controller('BacklogMilestoneController', ['$scope', BacklogMilestoneController])
module.controller('BacklogMilestonesController', ['$scope', '$rootScope', 'resource', BacklogMilestonesController])
module.controller('BacklogUserStoriesController', ['$scope', '$rootScope', '$q', 'resource', '$data', '$modal', BacklogUserStoriesController])
module.controller('BacklogController', ['$scope', '$rootScope', '$routeParams', 'resource', '$data', BacklogController])
module.controller('BacklogUserStoryModalController', ['$scope', '$rootScope', '$gmOverlay', 'resource', BacklogUserStoryModalController])
