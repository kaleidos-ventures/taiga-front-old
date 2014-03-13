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


class UserStoryViewController extends TaigaBaseController
    @.$inject = ["$scope", "$location", "$rootScope", "$routeParams", "$q",
                 "resource", "$data", "$confirm", "$gmFlash", "$i18next",
                 "$favico"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @rs, @data, @confirm, @gmFlash, @i18next, @favico) ->
        super(scope)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @favico.reset()
        @rootScope.pageTitle = @i18next.t("user-story.user-story")
        @rootScope.pageSection = 'user-stories'
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

        @scope.$on "select2:changed", (ctx, value) =>
            @scope.form.tags = value

        @scope.assignedToSelectOptions = {
            formatResult: @assignedToSelectOptionsShowMember
            formatSelection: @assignedToSelectOptionsShowMember
        }

        @scope.watcherSelectOptions = {
            allowClear: true
            formatResult: @watcherSelectOptionsShowMember
            formatSelection: @watcherSelectOptionsShowMember
            containerCssClass: "watcher-user"
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
                breadcrumb[1] = [@i18next.t('common.taskboard'), @rootScope.urls.taskboardUrl(@scope.projectSlug, @scope.userStory.milestone_slug)]
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
            @scope.projectTags = data

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

module = angular.module("taiga.controllers.user-story", [])
module.controller("UserStoryViewController", UserStoryViewController)
