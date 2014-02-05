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

KanbanController = ($scope, $rootScope, $routeParams, $q, rs, $data, $modal, $model, $i18next, $favico) ->
    $favico.reset()
    # Global Scope Variables
    $rootScope.pageTitle = $i18next.t('common.kanban')
    $rootScope.pageSection = 'kanban'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t('common.kanban'), null]
    ]

    formatUserStories = ->
        $scope.uss = {}
        for status in $scope.constants.usStatusesList
            $scope.uss[status.id] = []

        for us in $scope.userstories
            $scope.uss[us.status].push(us)

        return

    rs.resolve(pslug: $routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project

        $data.loadProject($scope).then ->
            $data.loadUsersAndRoles($scope).then ->
                $data.loadUserStories($scope).then ->
                    formatUserStories()

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

    initializeUsForm = (us, status) ->
        if us?
            return us

        result = {}
        result['project'] = $scope.projectId
        result['status'] = status or $scope.project.default_us_status
        points = {}
        for role in $scope.constants.computableRolesList
            points[role.id] = $scope.project.default_points
        result['points'] = points
        return result

    $scope.openCreateUsForm = (statusId) ->
        promise = $modal.open("us-form", {'us': initializeUsForm(null, statusId), 'type': 'create'})
        promise.then (us) ->
            newUs = $model.make_model("userstories", us)
            $scope.userstories.push(newUs)
            formatUserStories()

    $scope.openEditUsForm = (us) ->
        promise = $modal.open("us-form", {'us': us, 'type': 'edit'})
        promise.then ->
            formatUserStories()

    $scope.$on "sortable:changed", gm.utils.safeDebounced $scope, 100, ->
        saveUs = (us) ->
            if not us.isModified()
                return

            us._moving = true

            formatUserStories()
            promise = us.save()
            promise.then (us) ->
                us._moving = false

            promise.then null, (error) ->
                us.revert()
                us._moving = false
                $data.loadUserStories($scope)

        for statusId, uss of $scope.uss
            for us in uss
                us.status = parseInt(statusId, 10)
                saveUs(us)
    return


KanbanUsModalController = ($scope, $rootScope, $gmOverlay, $gmFlash, rs, $i18next) ->
    $scope.type = "create"
    $scope.formOpened = false

    # Load data
    $scope.defered = null
    $scope.context = null

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    openModal = ->
        loadProjectTags()
        $scope.form = $scope.context.us
        $scope.formOpened = true

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
            promise = $scope.form.save(false)
        else
            promise = rs.createUs($scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            $scope.$emit("spinner:stop")
            closeModal()
            $scope.overlay.close()
            $scope.form.id = data.id
            $scope.form.ref = data.ref
            $scope.defered.resolve($scope.form)
            $gmFlash.info($i18next.t('kanban.user-story-saved'))

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


KanbanUsController = ($scope, $rootScope, $q, $location) ->
    $scope.updateUsAssignation = (us, id) ->
        us.assigned_to = id || null
        us._moving = true
        us.save().then((us) ->
            us._moving = false
        , ->
            us.revert()
            us._moving = false
        )

    $scope.openUs = (projectSlug, usRef)->
        $location.url("/project/#{projectSlug}/user-story/#{usRef}")

    return


module = angular.module("taiga.controllers.kanban", [])
module.controller("KanbanController", ['$scope', '$rootScope', '$routeParams', '$q', 'resource', '$data',
                                       '$modal', "$model", "$i18next", "$favico",  KanbanController])
module.controller("KanbanUsController", ['$scope', '$rootScope', '$q', "$location", KanbanUsController])
module.controller("KanbanUsModalController", ['$scope', '$rootScope', '$gmOverlay', '$gmFlash', 'resource',
                                              "$i18next", KanbanUsModalController])
