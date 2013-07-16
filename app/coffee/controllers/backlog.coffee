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

BacklogController = ($scope, $rootScope, $routeParams, rs) ->
    # Global Scope Variables
    $rootScope.pageSection = 'backlog'
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

    # Load initial data
    rs.getProject($rootScope.projectId).then (project) ->
        $rootScope.project = project
        $rootScope.pageBreadcrumb = [project.name, "Backlog"]
        $rootScope.$broadcast("project:loaded", project)

    rs.getUsers($scope.projectId).then (users) ->
        $scope.users = users
        $rootScope.$broadcast("users:loaded", users)

    rs.getUsPoints($scope.projectId).then (points) ->
        $rootScope.constants.points = {}
        $rootScope.constants.pointsList = _.sortBy(points, "order")

        for item in points
            $rootScope.constants.points[item.id] = item

        $rootScope.$broadcast("points:loaded", points)


BacklogUserStoryFormController = ($scope, $rootScope, $gmOverlay, rs) ->
    $scope.type = "create"
    $scope.formOpened = false

    # Load data
    promise = rs.getUsStatuses($scope.projectId)
    promise.then (result) ->
        $scope.usstatuses = result

    $scope.submit = ->
        $scope.overlay.close()
        if $scope.type == "create"
            promise = rs.createUserStory($scope.form)
            promise.then (us) ->
                $rootScope.$broadcast("userstory-form:create", us)
                $scope.formOpened = false

        else
            promise = $scope.form.save()
            promise.then ->
                $rootScope.$broadcast("userstory-form:update")
                $scope.formOpened = false

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.type == "create"
            $scope.form = {}
        else
            $scope.form.revert()

    $scope.$on "userstory-form:open", (ctx, type, form={}) ->
        $scope.type = type
        $scope.form = form
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

    $scope.$on "userstory-form:close", ->
        $scope.formOpened = false


BacklogUserStoriesCtrl = ($scope, $rootScope, $q, rs) ->
    # Local scope variables
    $scope.filtersOpened = false
    $scope.form = {}

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)
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

    rs.getUnassignedUserStories($scope.projectId).then (unassingedUs) ->
        projectId = parseInt($scope.projectId, 10)

        $scope.unassingedUs = _.filter(unassingedUs, {"project": projectId, milestone: null})
        $scope.unassingedUs = _.sortBy($scope.unassingedUs, "order")

        generateTagList()
        filterUsBySelectedTags()
        calculateStats()

        $rootScope.$broadcast("userstories:loaded")

    $scope.openCreateUserStoryForm = ->
        $rootScope.$broadcast("userstory-form:open", "create",
                              {us:[], project:$scope.projectId})

    $scope.openEditUserStoryForm = (us) ->
        $rootScope.$broadcast("userstory-form:open", "edit", us)

    $scope.removeUs = (us) ->
        us.remove().then ->
            index = $scope.unassingedUs.indexOf(us)
            $scope.unassingedUs.splice(index, 1)

            calculateStats()
            generateTagList()
            filterUsBySelectedTags()

    $scope.saveUsPoints = (us, id) ->
        us.points = id
        us.save().then calculateStats, (data, status) ->
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


BacklogMilestonesController = ($scope, $rootScope, rs) ->
    # Local scope variables
    $scope.sprintFormOpened = false

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)
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
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)
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
module.controller('BacklogUserStoriesCtrl', ['$scope', '$rootScope', '$q', 'resource', BacklogUserStoriesCtrl])
module.controller('BacklogController', ['$scope', '$rootScope', '$routeParams', 'resource', BacklogController])
module.controller('BacklogUserStoryFormController',
                    ['$scope', '$rootScope', '$gmOverlay', 'resource', BacklogUserStoryFormController])
