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


class UserStoryViewController extends TaigaPageController
    @.$inject = ["$scope", "$location", "$rootScope", "$routeParams", "$q",
                 "resource", "$data", "$confirm", "$gmFlash", "$i18next",
                 "$favico"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @rs, @data, @confirm, @gmFlash, @i18next, @favico) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    section: 'user-stories'
    getTitle: ->
        @i18next.t("user-story.user-story")

    initialize: ->
        @debounceMethods()
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t("user-story.user-story"), null],
        ]

        @scope.userStory = {}
        @scope.form = {'points':{}}
        @scope.totalPoints = 0
        @scope.points = {}
        @scope.newAttachments = []
        @scope.attachments = []

        # Load initial data
        @rs.resolve(pslug: @routeParams.pslug, usref: @routeParams.ref).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.userStoryId = data.us

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @loadUserStory()
                    @loadAttachments()
                    @loadHistorical()
                    @loadProjectTags()

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @tagsSelectOptionsShowColorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @assignedToSelectOptionsShowMember
            formatSelection: @assignedToSelectOptionsShowMember
        }

        @scope.watcherSelectOptions = {
            allowClear: true
            formatResult: @watcherSelectOptionsShowMember
            formatSelection: @watcherSelectOptionsShowMember
            containerCssClass: "watchers-selector"
        }

    calculateTotalPoints: (us) ->
        total = 0
        for roleId, pointId of us.points
            total += @scope.constants.points[pointId].value
        return total

    loadAttachments: ->
        @rs.getUserStoryAttachments(@scope.projectId, @scope.userStoryId).then (attachments) =>
            @scope.attachments = attachments

    loadUserStory: ->
        params = @location.search()
        @rs.getUserStory(@scope.projectId, @scope.userStoryId, params).then (userStory) =>
            @scope.userStory = _.cloneDeep(userStory)
            @scope.form = userStory

            # TODO: More general solution must be found.
            # This hack is used to take care on save user story as PATCH requests
            # and save correctly the multiple deep levels attributes
            @scope.$watch('form.points', =>
                if JSON.stringify(@scope.form.points) != JSON.stringify(@scope.userStory.points)
                    @scope.form.points = _.clone(@scope.form.points)
            , true)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            if @scope.userStory.milestone == null
                breadcrumb[1] = [@i18next.t('common.backlog'), @rootScope.urls.backlogUrl(@scope.projectSlug)]
            else
                breadcrumb[1] = [
                    @i18next.t('common.taskboard'),
                    @rootScope.urls.taskboardUrl(@scope.projectSlug, @scope.userStory.milestone_slug)
                ]
            breadcrumb[2] = [@i18next.t("user-story.user-story") + " ##{userStory.ref}", null]
            @rootScope.pageTitle = "#{@i18next.t("user-story.user-story")} - ##{userStory.ref}"
            @rootScope.pageBreadcrumb = breadcrumb

            @scope.totalPoints = @calculateTotalPoints(userStory)
            for roleId, pointId of userStory.points
                @scope.points[roleId] = @scope.constants.points[pointId].name

    loadHistorical: (page=1) ->
        @rs.getUserStoryHistorical(@scope.userStoryId, {page: page}).then (historical) =>
            if @scope.historical and page != 1
                historical.models = _.union(@scope.historical.models, historical.models)

            @scope.showMoreHistoricaButton = historical.models.length < historical.count
            @scope.historical = historical

    loadMoreHistorical: ->
        page = if @scope.historical then @scope.historical.current + 1 else 1
        @loadHistorical(page=page)

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    saveNewAttachments: ->
        if @scope.newAttachments.length == 0
            return

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadUserStoryAttachment(@scope.projectId, @scope.userStoryId, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @scope.newAttachments = []
                @loadAttachments()

    # Debounced Method (see debounceMethods method)
    submit: =>
        @scope.$emit("spinner:start")

        promise = @scope.form.save()

        promise.then (userStory) =>
            @scope.$emit("spinner:stop")
            @loadUserStory()
            @loadHistorical()
            @saveNewAttachments()
            @gmFlash.info(@i18next.t('user-story.user-story-saved'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    getQueryParams: ->
        @location.search()

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () ->
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    removeUserStory: (userStory) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () =>
            userStory.remove().then =>
                @location.url("/project/#{@scope.projectSlug}/backlog")

    tagsSelectOptionsShowColorizedTags: (option, container) ->
        hash = hex_sha1(option.text.trim().toLowerCase())
        color = hash
            .substring(0,6)
            .replace('8','0')
            .replace('9','1')
            .replace('a','2')
            .replace('b','3')
            .replace('c','4')
            .replace('d','5')
            .replace('e','6')
            .replace('f','7')

        container.parent().css('background', "##{color}")
        container.text(option.text)
        return

    assignedToSelectOptionsShowMember: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
         return "<span\">#{option.text}</span>"

    watcherSelectOptionsShowMember: (option, container) =>
        member = _.find(@scope.project.active_memberships, {user: parseInt(option.id, 10)})
        # TODO: Make me more beautiful and elegant
        return "<span style=\"padding: 0px 5px;
                              border-left: 15px solid #{member.color}\">#{member.full_name}</span>"

moduleDeps = ["taiga.services.resource", "taiga.services.data", "gmConfirm",
              "gmFlash", "i18next", "favico"]
module = angular.module("taiga.controllers.user-story", moduleDeps)
module.controller("UserStoryViewController", UserStoryViewController)
