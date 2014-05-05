# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


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
                 'resource', "$confirm", "$q", "$i18next", "$favico", "$gmFlash"]
    constructor: (@scope, @rootScope, @location, @routeParams, @data, @rs, @confirm, @q, @i18next, @favico, @gmFlash) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        @_savePage = @savePage
        @savePage = gm.utils.safeDebounced @scope, 500, @_savePage

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
            return null

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadWikiPageAttachment(@scope.projectId, @scope.page.id, attachment)
            promise.then =>
                @scope.newAttachments = _.without(@scope.newAttachments, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @loadAttachments(@scope.page)

        promise.then null, (data) =>
            @loadAttachments(@scope.page)
            @gmFlash.error(@i18next.t("wiki.upload-attachment-error"))

        return promise

    openEditForm: ->
        @scope.formOpened = true
        @scope.content = @scope.page.content

    discardCurrentChanges: ->
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

        return promise

    deletePage: ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then =>
            @scope.page.remove().then =>
                @scope.page = undefined
                @scope.content = ""
                @scope.attachments = []
                @scope.newAttachments = []
                @scope.formOpened = true
        return promise

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

    constructor: (@scope, @rootScope, @location, @routeParams,
                  @data, @rs, @confirm, @q, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'wiki'
    getTitle: ->
        return """
        #{@i18next.t("common.wiki")} - #{@routeParams.slug}
        - #{@i18next.t("wiki-historical.historical")}
        """

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

    loadAttachments: (page) ->
        @rs.getWikiPageAttachments(@scope.projectId, page.id).then (attachments) =>
            @scope.attachments = attachments


moduleDeps = ['taiga.services.data', 'taiga.services.resource', "gmConfirm",
              "i18next", "favico", 'gmFlash']
module = angular.module("taiga.controllers.wiki", moduleDeps)
module.controller("WikiController", WikiController)
module.controller("WikiHelpController", WikiHelpController)
module.controller("WikiHistoricalController", WikiHistoricalController)
