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

WikiController = ($scope, $rootScope, $location, $routeParams, $data, rs, $confirm, $q) ->
    $rootScope.pageSection = 'wiki'
    $rootScope.projectId = parseInt($routeParams.pid, 10)
    $rootScope.slug = $routeParams.slug
    $rootScope.pageBreadcrumb = [
        ["", ""]
        ["Wiki", $rootScope.urls.wikiUrl($rootScope.projectId, "home")]
        [$routeParams.slug, null]
    ]

    $scope.formOpened = false
    $scope.form = {}
    $scope.newAttachments = []
    $scope.attachments = []

    projectId = $rootScope.projectId

    loadAttachments = (page) ->
        rs.getWikiPageAttachments(projectId, page.id).then (attachments) ->
            $scope.attachments = attachments

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attrachment in $scope.newAttachments
            promise = rs.uploadWikiPageAttachment(projectId, $scope.page.id, attrachment)
            promises.push(promise)

        promise = Q.all(promises)
        promise.then ->
            $scope.newAttachments = []
            loadAttachments($scope.page)

    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            promise = rs.getWikiPage(projectId, $rootScope.slug)
            promise.then (page) ->
                $scope.page = page
                $scope.content = page.content
                loadAttachments(page)

            promise.then null, (data) ->
                $scope.formOpened = true

    $scope.openEditForm = ->
        $scope.formOpened = true
        $scope.content = $scope.page.content

    $scope.discartCurrentChanges = ->
        $scope.newAttachments = []
        if $scope.page is undefined
            $scope.content = ""
        else
            $scope.formOpened = false
            $scope.content = $scope.page.content

    $scope.savePage = gm.utils.safeDebounced $scope, 400, ->
        if $scope.page is undefined
            content = $scope.content

            promise = rs.createWikiPage(projectId, $rootScope.slug, content)

            promise.then (page) ->
                $scope.page = page
                saveNewAttachments()
                $scope.formOpened = false

            promise.then null, (data) ->
                $scope.checksleyErrors = data
        else
            $scope.page.content = $scope.content

            promise = $scope.page.save()

            promise.then (page) ->
                $scope.page = page
                $scope.formOpened = false
                $scope.content = $scope.page.content
                saveNewAttachments()

            promise.then null, (data) ->
                $scope.checksleyErrors = data

    $scope.deletePage = ->
        $scope.page.remove().then ->
            $scope.page = undefined
            $scope.content = ""
            $scope.formOpened = true

    $scope.deleteAttachment = (attachment) ->
        promise = $confirm.confirm("Are you sure?")
        promise.then () ->
            $scope.attachments = _.without($scope.attachments, attachment)
            attachment.remove()

    $scope.deleteNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)


WikiHistoricalController = ($scope, $rootScope, $location, $routeParams, $data, rs, $confirm, $q) ->
    $rootScope.pageSection = 'wiki'
    $rootScope.projectId = parseInt($routeParams.pid, 10)
    $rootScope.slug = $routeParams.slug
    $rootScope.pageBreadcrumb = [
        ["", ""]
        ["Wiki", $rootScope.urls.wikiUrl($rootScope.projectId, "home")]
        [$routeParams.slug, null]
        ["Historical", null]
    ]

    $scope.attachments = []

    projectId = $rootScope.projectId

    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            promise = rs.getWikiPage(projectId, $rootScope.slug)
            promise.then (page) ->
                $scope.page = page
                $scope.content = page.content
                loadAttachments(page)
                loadHistorical()

    loadAttachments = (page) ->
        rs.getWikiPageAttachments(projectId, page.id).then (attachments) ->
            $scope.attachments = attachments

    loadHistorical = (page=1) ->
        rs.getWikiPageHistorical($scope.page.id, {page: page}).then (historical) ->
            if $scope.historical and page != 1
                historical.models = _.union($scope.historical.models, historical.models)

            $scope.showMoreHistoricaButton = historical.models.length < historical.count
            $scope.historical = historical

    $scope.loadMoreHistorical = ->
        page = if $scope.historical then $scope.historical.current + 1 else 1
        loadHistorical(page=page)


module = angular.module("greenmine.controllers.wiki", [])
module.controller("WikiController", ['$scope', '$rootScope', '$location', '$routeParams',
                                     '$data', 'resource', "$confirm", "$q", WikiController])
module.controller("WikiHistoricalController", ['$scope', '$rootScope', '$location', '$routeParams',
                                               '$data', 'resource', "$confirm", "$q",   WikiHistoricalController])
