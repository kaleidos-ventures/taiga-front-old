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


class UserStoryViewController extends TaigaDetailPageController
    @.$inject = ["$scope", "$location", "$rootScope", "$routeParams", "$q",
                 "resource", "$data", "$confirm", "$gmFlash", "$i18next",
                 "$favico", "selectOptions"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @rs, @data,
                  @confirm, @gmFlash, @i18next, @favico, @selectOptions) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        @_submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, @_submit

    section: 'user-stories'
    getTitle: ->
        @i18next.t("user-story.user-story")

    uploadAttachmentMethod: "uploadUserStoryAttachment"
    getAttachmentsMethod: "getUserStoryAttachments"
    getHistoricalMethod: "getUserStoryHistorical"
    objectIdAttribute: "userStoryId"

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
                @onRemoveUrl = @rootScope.urls.projectHomeUrl(@scope.project, true)
                @data.loadUsersAndRoles(@scope).then =>
                    @loadUserStory()
                    @loadAttachments()
                    @loadHistorical()
                    @loadProjectTags()

        @scope.tagsSelectOptions = {
            multiple: true
            simple_tags: true
            tags: @getTagsList
            formatSelection: @selectOptions.colorizedTags
            containerCssClass: "tags-selector"
        }

        @scope.assignedToSelectOptions = {
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
        }

        @scope.watcherSelectOptions = {
            allowClear: true
            formatResult: @selectOptions.member
            formatSelection: @selectOptions.member
            containerCssClass: "watchers-selector"
        }

    calculateTotalPoints: (us) ->
        total = 0
        for roleId, pointId of us.points
            total += @scope.constants.points[pointId].value
        return total

    loadUserStory: ->
        params = @location.search()
        @rs.getUserStory(@scope.projectId, @scope.userStoryId, params).then (userStory) =>
            @scope.form = _.cloneDeep(userStory)
            @scope.userStory = userStory

            # TODO: More general solution must be found.
            # This hack is used to take care on save user story as PATCH requests
            # and save correctly the multiple deep levels attributes
            @scope.$watch('form.points', =>
                if JSON.stringify(@scope.form.points) != JSON.stringify(@scope.userStory.points)
                    @scope.form.points = _.clone(@scope.form.points)
            , true)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            if @scope.project.is_backlog_activated
                if @scope.userStory.milestone == null
                    breadcrumb[1] = [@i18next.t('common.backlog'), @rootScope.urls.backlogUrl(@scope.projectSlug)]
                else
                    breadcrumb[1] = [
                        @scope.userStory.milestone_name,
                        @rootScope.urls.taskboardUrl(@scope.projectSlug, @scope.userStory.milestone_slug)
                    ]
                breadcrumb[2] = [@i18next.t("user-story.user-story") + " ##{userStory.ref}", null]
            else if @scope.project.is_kanban_activated
                breadcrumb[1] = [@i18next.t('common.kanban'), @rootScope.urls.kanbanUrl(@scope.projectSlug)]
                breadcrumb[2] = [@i18next.t("user-story.user-story") + " ##{userStory.ref}", null]
            else
                breadcrumb[1] = [@i18next.t("user-story.user-story") + " ##{userStory.ref}", null]

            @rootScope.pageTitle = "#{@i18next.t("user-story.user-story")} - ##{userStory.ref}"
            @rootScope.pageBreadcrumb = breadcrumb

            @scope.totalPoints = @calculateTotalPoints(userStory)
            for roleId, pointId of userStory.points
                @scope.points[roleId] = @scope.constants.points[pointId].name

    # Debounced Method (see debounceMethods method)
    submit: =>
        @scope.$emit("spinner:start")
        for key, value of @scope.form
            @scope.userStory[key] = value

        promise = @scope.userStory.save()

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


moduleDeps = ["taiga.services.resource", "taiga.services.data", "gmConfirm",
              "gmFlash", "i18next", "favico"]
module = angular.module("taiga.controllers.user-story", moduleDeps)
module.controller("UserStoryViewController", UserStoryViewController)
