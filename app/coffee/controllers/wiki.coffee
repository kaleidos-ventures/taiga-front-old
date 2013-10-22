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

WikiController = ($scope, $rootScope, $location, $routeParams, rs) ->
    $rootScope.pageSection = 'wiki'
    $rootScope.pageBreadcrumb = ["Project", "Wiki", $routeParams.slug]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.formOpened = true
    $scope.form = {}

    projectId = $rootScope.projectId
    slug = $routeParams.slug

    promise = rs.getWikiPage(projectId, slug)
    promise.then (page) ->
        $scope.page = page
        $scope.content = page.content
        loadAttachments(page)

    promise.then null, ->
        $scope.formOpened = true

    loadAttachments = (page) ->
        rs.getWikiPageAttachments(projectId, page.id).then (attachments) ->
            $scope.attachments = attachments

    $scope.savePage = ->
        if $scope.page is undefined
            content = $scope.content
            rs.createWikiPage(projectId, slug, content).then (page) ->
                $scope.formOpened = false
                rs.uploadWikiPageAttachment(projectId, page.id, $scope.attachment).then ->
                    loadAttachments($scope.page)
        else
            $scope.page.content = $scope.content
            $scope.page.save().then (page) ->
                $scope.formOpened = false
                rs.uploadWikiPageAttachment(projectId, page.id, $scope.attachment).then ->
                    loadAttachments($scope.page)

    $scope.openEditForm = ->
        $scope.formOpened = true
        $scope.content = $scope.page.content

    $scope.discartCurrentChanges = ->
        $scope.formOpened = false
        $scope.content = $scope.page.content

    $scope.removeAttachment = (attachment) ->
        $scope.attachments = _.reject($scope.attachments, {"id": attachment.id})
        attachment.remove()


module = angular.module("greenmine.controllers.wiki", [])
module.controller("WikiController", ['$scope', '$rootScope', '$location', '$routeParams', 'resource', WikiController])
