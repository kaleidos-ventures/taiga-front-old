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


class TasksViewController extends TaigaBaseController
    @.$inject = ['$scope', '$location', '$rootScope', '$routeParams', '$q',
                 '$confirm', 'resource', "$data", "$gmFlash", "$i18next",
                 "$favico"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @confirm, @rs, @data, @gmFlash, @i18next, @favico) ->
        super(scope)

    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @favico.reset()
        @rootScope.pageTitle = @i18next.t("common.tasks")
        @rootScope.pageSection = 'tasks'
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t("common.tasks"), null],
        ]
        @scope.task = {}
        @scope.form = {}
        @scope.updateFormOpened = false
        @scope.newAttachments = []
        @scope.attachments = []

        # Load initial data
        @rs.resolve(pslug: @routeParams.pslug, taskref: @routeParams.ref).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @rootScope.taskId = data.task
            @rootScope.taskRef = @routeParams.ref

            @data.loadProject(@scope).then =>
                @data.loadUsersAndRoles(@scope).then =>
                    @loadTask()
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

    loadAttachments: ->
        @rs.getTaskAttachments(@scope.projectId, @scope.taskId).then (attachments) =>
            @scope.attachments = attachments

    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @scope.projectTags = data

    loadTask: ->
        @rs.getTask(@scope.projectId, @scope.taskId).then (task) =>
            @scope.task = task
            @scope.form = _.extend({}, @scope.task._attrs)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            breadcrumb[1] = [@i18next.t('common.tasks'), @rootScope.urls.taskboardUrl(@rootScope.projectSlug, @scope.task.milestone_slug)]
            breadcrumb[2] = ["##{task.ref}", null]
            @rootScope.pageTitle = "#{@i18next.t("common.tasks")} - ##{task.ref}"

            @rootScope.pageBreadcrumb = breadcrumb

    loadHistorical: (page=1) ->
        @rs.getTaskHistorical(@scope.taskId, {page: page}).then (historical) =>
            if @scope.historical and page != 1
                historical.models = @scope.historical.models.concat(historical.models)

            @scope.showMoreHistoricaButton = historical.models.length < historical.count
            @scope.historical = historical

    loadMoreHistorical: ->
        page = if @scope.historical then @scope.historical.current + 1 else 1
        @loadHistorical(page=page)

    saveNewAttachments: ->
        if @scope.newAttachments.length == 0
            return

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs.uploadTaskAttachment(@scope.projectId, @scope.taskId, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @scope.newAttachments = []
                @loadAttachments()


    # Debounced Method (see debounceMethods method)
    submit: =>
        @scope.$emit("spinner:start")
        for key, value of @scope.form
            @scope.task[key] = value

        promise = @scope.task.save()
        promise.then (task) =>
            @scope.$emit("spinner:stop")
            @saveNewAttachments()
            @loadTask()
            @loadHistorical()
            @gmFlash.info(@i18next.t("task.task-saved"))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then () =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    removeTask: (task) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then =>
            task.remove().then =>
                @location.url("/project/#{@scope.projectSlug}/taskboard/#{task.milestone_slug}")

    assignedToSelectOptionsShowMember: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
         return "<span\">#{option.text}</span>"

    watcherSelectOptionsShowMember: (option, container) =>
        member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
        # TODO: Make me more beautiful and elegant
        return "<span style=\"padding: 0px 5px;
                              border-left: 15px solid #{member.color}\">#{member.full_name}</span>"


module = angular.module("taiga.controllers.tasks", [])
module.controller("TasksViewController", TasksViewController)
