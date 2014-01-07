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

WikiController = ($scope, $rootScope, $location, $routeParams, $data, rs, $confirm, $q, $i18next) ->
    $rootScope.pageTitle = "#{$i18next.t("common.wiki")} - #{$routeParams.slug}"
    $rootScope.pageSection = 'wiki'
    $rootScope.pageBreadcrumb = [
        ["", ""]
        [$i18next.t("common.wiki"), $rootScope.urls.wikiUrl($rootScope.projectSlug, "home")]
        [$routeParams.slug, null]
    ]

    $scope.formOpened = false
    $scope.form = {}
    $scope.newAttachments = []
    $scope.attachments = []

    projectId = $rootScope.projectId

    loadAttachments = (page) ->
        rs.getWikiPageAttachments($scope.projectId, page.id).then (attachments) ->
            $scope.attachments = attachments

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attachment in $scope.newAttachments
            promise = rs.uploadWikiPageAttachment($scope.projectId, $scope.page.id, attachment)
            promises.push(promise)

        promise = $q.all(promises)
        promise.then ->
            $scope.newAttachments = []
            loadAttachments($scope.page)


    rs.resolve($routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $rootScope.slug = $routeParams.slug

        $data.loadProject($scope).then ->
            $data.loadUsersAndRoles($scope).then ->
                promise = rs.getWikiPage($scope.projectId, $rootScope.slug)
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
            promise = rs.createWikiPage($scope.projectId, $rootScope.slug, $scope.content)

            promise.then (page) ->
                $scope.page = page
                $scope.formOpened = false
                $scope.content = $scope.page.content
                saveNewAttachments()

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
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $scope.page.remove().then ->
                $scope.page = undefined
                $scope.content = ""
                $scope.attachments = []
                $scope.newAttachments = []
                $scope.formOpened = true

    $scope.deleteAttachment = (attachment) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $scope.attachments = _.without($scope.attachments, attachment)
            attachment.remove()

    $scope.deleteNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)

    return


WikiHistoricalController = ($scope, $rootScope, $location, $routeParams, $data, rs, $confirm, $q, $i18next) ->
    $rootScope.pageTitle = "#{$i18next.t("common.wiki")} - #{$routeParams.slug} - #{$i18next.t("wiki-historical.historical")}"
    $rootScope.pageSection = 'wiki'
    $rootScope.pageBreadcrumb = [
        ["", ""]
        [$i18next.t("common.wiki"), $rootScope.urls.wikiUrl($rootScope.projectSlug, "home")]
        [$routeParams.slug, $rootScope.urls.wikiUrl($rootScope.projectSlug, $routeParams.slug)]
        [$i18next.t("wiki-historical.historical"), null]
    ]

    $scope.attachments = []

    rs.resolve($routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $rootScope.slug = $routeParams.slug

        $data.loadProject($scope).then ->
            $data.loadUsersAndRoles($scope).then ->
                promise = rs.getWikiPage($scope.projectId, $rootScope.slug)
                promise.then (page) ->
                    $scope.page = page
                    $scope.content = page.content
                    loadAttachments(page)
                    loadHistorical()

    loadAttachments = (page) ->
        rs.getWikiPageAttachments($scope.projectId, page.id).then (attachments) ->
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

    $scope.$on "wiki:restored", (ctx, data) ->
        promise = rs.getWikiPage($scope.projectId, $rootScope.slug)
        promise.then (page) ->
            $scope.page = page
            $scope.content = page.content
            loadAttachments(page)
            loadHistorical()

    return


WikiHistoricalItemController = ($scope, $rootScope, rs, $confirm, $gmFlash, $q, $i18next) ->
    $scope.showChanges = false

    $scope.showContent = true
    $scope.showPreviousDiff = false
    $scope.showCurrentDiff = false

    $scope.toggleShowChanges = ->
        $scope.showChanges = not $scope.showChanges

    $scope.activeShowContent = ->
        $scope.showContent = true
        $scope.showPreviousDiff = false
        $scope.showCurrentDiff = false

    $scope.activeShowPreviousDiff = ->
        $scope.showContent = false
        $scope.showPreviousDiff = true
        $scope.showCurrentDiff = false

    $scope.activeShowCurrentDiff = ->
        $scope.showContent = false
        $scope.showPreviousDiff = false
        $scope.showCurrentDiff = true

    $scope.restoreWikiPage = (hitem) ->
        date = moment(hitem.created_date).format("llll")

        promise = $confirm.confirm $i18next.t("wiki-historical.gone-back-sure", {'date': date})
        promise.then () ->
            promise = rs.restoreWikiPage(hitem.object_id, hitem.id)

            promise.then (data) ->
                $scope.$emit("wiki:restored")
                $gmFlash.info($i18next.t("wiki-historical.gone-back-success", {'date': date}))

            promise.then null, (data, status) ->
                $gmFlash.error($i18next.t("wiki-historical.gone-back-error"))

    return


module = angular.module("greenmine.controllers.wiki", [])
module.controller("WikiController", ['$scope', '$rootScope', '$location', '$routeParams',
                                     '$data', 'resource', "$confirm", "$q", "$i18next", WikiController])
module.controller("WikiHistoricalController", ['$scope', '$rootScope', '$location', '$routeParams',
                                               '$data', 'resource', "$confirm", "$q", "$i18next",
                                               WikiHistoricalController])
module.controller("WikiHistoricalItemController", ['$scope', '$rootScope', 'resource', '$confirm',
                                                   '$gmFlash',  '$q', "$i18next", WikiHistoricalItemController])

