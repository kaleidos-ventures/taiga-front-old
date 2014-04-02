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

class WikiHelpController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$routeParams', '$data',
                 'resource', "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @routeParams, @data, @rs, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'wiki'
    getTitle: ->
        "#{@i18next.t("common.wiki-help")}"

    initialize: ->
        @rootScope.pageBreadcrumb = [
            [@i18next.t("common.wiki-help"), null]
        ]

class WikiController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams', '$data',
                 'resource', "$confirm", "$q", "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @location, @routeParams, @data, @rs, @confirm, @q, @i18next, @favico) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        savePage = @savePage
        @savePage = gm.utils.safeDebounced @scope, 500, savePage

    section: 'wiki'
    getTitle: ->
        "#{@i18next.t("common.wiki")} - #{@routeParams.slug}"

    initialize: ->
        @debounceMethods()
        @rootScope.pageBreadcrumb = [
            ["", ""]
            [@i18next.t("common.wiki"), @rootScope.urls.wikiUrl(@rootScope.projectSlug, "home")]
            [@routeParams.slug, null]
        ]

        @scope.formOpened = false
        @scope.form = {}
        @scope.newAttachments = []
        @scope.attachments = []

        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.slug = @routeParams.slug

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    promise = @rs.getWikiPage(@scope.projectId, @rootScope.slug)
                    promise.then (page) =>
                        @scope.page = page
                        @scope.content = page.content
                        @loadAttachments(page)

                    promise.then null, (data) =>
                        @scope.formOpened = true

    loadAttachments: (page) ->
        @rs.getWikiPageAttachments(@scope.projectId, page.id).then (attachments) =>
            @scope.attachments = attachments

    saveNewAttachments: ->
        if @scope.newAttachments.length == 0
            return

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadWikiPageAttachment(@scope.projectId, @scope.page.id, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            @scope.newAttachments = []
            @loadAttachments(@scope.page)


    openEditForm: ->
        @scope.formOpened = true
        @scope.content = @scope.page.content

    discartCurrentChanges: ->
        @scope.newAttachments = []
        if @scope.page is undefined
            @scope.content = ""
        else
            @scope.formOpened = false
            @scope.content = @scope.page.content

    # Debounced Method (see debounceMethods method)
    savePage: =>
        if @scope.page is undefined
            promise = @rs.createWikiPage(@scope.projectId, @rootScope.slug, @scope.content)

        else
            @scope.page.content = @scope.content
            promise = @scope.page.save()

        promise.then (page) =>
            @scope.page = page
            @scope.formOpened = false
            @scope.content = @scope.page.content
            @saveNewAttachments()

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    deletePage: ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then =>
            @scope.page.remove().then =>
                @scope.page = undefined
                @scope.content = ""
                @scope.attachments = []
                @scope.newAttachments = []
                @scope.formOpened = true

    deleteAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    deleteNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)


class WikiHistoricalController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams', '$data',
                 'resource', "$confirm", "$q", "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @location, @routeParams, @data, @rs, @confirm, @q, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'wiki'
    getTitle: ->
        "#{@i18next.t("common.wiki")} - #{@routeParams.slug} - #{@i18next.t("wiki-historical.historical")}"

    initialize: ->
        @rootScope.pageBreadcrumb = [
            ["", ""]
            [@i18next.t("common.wiki"), @rootScope.urls.wikiUrl(@rootScope.projectSlug, "home")]
            [@routeParams.slug, @rootScope.urls.wikiUrl(@rootScope.projectSlug, @routeParams.slug)]
            [@i18next.t("wiki-historical.historical"), null]
        ]

        @scope.attachments = []

        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.slug = @routeParams.slug

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    promise = @rs.getWikiPage(@scope.projectId, @rootScope.slug)
                    promise.then (page) =>
                        @scope.page = page
                        @scope.content = page.content
                        @loadAttachments(page)
                        @loadHistorical()

        @scope.$on "wiki:restored", (ctx, data) =>
            promise = @rs.getWikiPage(@scope.projectId, @rootScope.slug)
            promise.then (page) =>
                @scope.page = page
                @scope.content = page.content
                @loadAttachments(page)
                @loadHistorical()

    loadAttachments: (page) ->
        @rs.getWikiPageAttachments(@scope.projectId, page.id).then (attachments) =>
            @scope.attachments = attachments

    loadHistorical: (page=1) ->
        @rs.getWikiPageHistorical(@scope.page.id, {page: page}).then (historical) =>
            if page == 1
                @scope.currentVersion = _.first(historical.models)
                historical.models = _.rest(historical.models)
            else
                historical.models = _.union(@scope.historical.models, historical.models)

            @scope.showMoreHistoricaButton = historical.models.length < historical.count - 1
            @scope.historical = historical

    loadMoreHistorical: ->
        page = if @scope.historical then @scope.historical.current + 1 else 1
        @loadHistorical(page=page)


class WikiHistoricalItemController extends TaigaBaseController
    @.$inject = ['$scope', '$rootScope', 'resource', '$confirm', '$gmFlash',
                 '$q', "$i18next"]
    constructor: (@scope, @rootScope, @rs, @confirm, @gmFlash, @q, @i18next) ->
        super(scope)

    initialize: ->
        @scope.showChanges = false
        @scope.showContent = true
        @scope.showPreviousDiff = false
        @scope.showCurrentDiff = false

    toggleShowChanges: ->
        @scope.showChanges = not @scope.showChanges

    activeShowContent: ->
        @scope.showContent = true
        @scope.showPreviousDiff = false
        @scope.showCurrentDiff = false

    activeShowPreviousDiff: ->
        @scope.showContent = false
        @scope.showPreviousDiff = true
        @scope.showCurrentDiff = false

    activeShowCurrentDiff: ->
        @scope.showContent = false
        @scope.showPreviousDiff = false
        @scope.showCurrentDiff = true

    restoreWikiPage: (hitem) ->
        date = moment(hitem.created_date).format("llll")

        promise = @confirm.confirm @i18next.t("wiki-historical.gone-back-sure", {'date': date})
        promise.then () =>
            promise = @rs.restoreWikiPage(hitem.object_id, hitem.id)

            promise.then (data) =>
                @scope.$emit("wiki:restored")
                @gmFlash.info(@i18next.t("wiki-historical.gone-back-success", {'date': date}))

            promise.then null, (data, status) =>
                @gmFlash.error(@i18next.t("wiki-historical.gone-back-error"))

moduleDeps = ['taiga.services.data', 'taiga.services.resource', "gmConfirm",
              "i18next", "favico", 'gmFlash']
module = angular.module("taiga.controllers.wiki", moduleDeps)
module.controller("WikiController", WikiController)
module.controller("WikiHelpController", WikiHelpController)
module.controller("WikiHistoricalController", WikiHistoricalController)
module.controller("WikiHistoricalItemController", WikiHistoricalItemController)
