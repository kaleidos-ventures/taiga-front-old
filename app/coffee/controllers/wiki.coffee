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

WikiController = ($scope, $rootScope, $location, $routeParams, $data, rs) ->
    $rootScope.pageSection = 'wiki'
    $rootScope.projectId = parseInt($routeParams.pid, 10)
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
    slug = $routeParams.slug

    $data.loadProject($scope)

    promise = rs.getWikiPage(projectId, slug)
    promise.then (page) ->
        $scope.page = page
        $scope.content = page.content
        loadAttachments(page)

    promise.then null, (data) ->
        $scope.formOpened = true

    loadAttachments = (page) ->
        rs.getWikiPageAttachments(projectId, page.id).then (attachments) ->
            $scope.attachments = attachments
        $scope.newAttachments = []

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

    $scope.savePage = ->
        if $scope.page is undefined
            content = $scope.content
            rs.createWikiPage(projectId, slug, content).then (page) ->
                $scope.page = page
                saveNewAttachments()
                $scope.formOpened = false
        else
            $scope.page.content = $scope.content
            $scope.page.save().then (page) ->
                $scope.page = page
                saveNewAttachments()
                $scope.formOpened = false

    saveNewAttachments = ->
        _.forEach $scope.newAttachments, (newAttach) ->
            rs.uploadWikiPageAttachment(projectId, $scope.page.id, newAttach).then (attach) ->
                $scope.deleteNewAttachment(newAttach)
                $scope.attachments.push(attach)

    $scope.deletePage = ->
        $scope.page.remove().then ->
            $scope.page = undefined
            $scope.content = ""
            $scope.formOpened = true

    $scope.deleteAttachment = (attachment) ->
        $scope.attachments = _.without($scope.attachments, attachment)
        attachment.remove()

    $scope.deleteNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)


module = angular.module("greenmine.controllers.wiki", [])
module.controller("WikiController", ['$scope', '$rootScope', '$location', '$routeParams', '$data', 'resource', WikiController])
