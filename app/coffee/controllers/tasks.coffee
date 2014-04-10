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


class TasksViewController extends TaigaDetailPageController
    @.$inject = ['$scope', '$location', '$rootScope', '$routeParams', '$q',
                 '$confirm', 'resource', "$data", "$gmFlash", "$i18next",
                 "$favico", "selectOptions"]
    constructor: (@scope, @location, @rootScope, @routeParams, @q, @confirm,
                  @rs, @data, @gmFlash, @i18next, @favico, @selectOptions) ->
        super(scope, rootScope, favico)

    debounceMethods: ->
        @_submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, @_submit

    section: 'tasks'
    getTitle: ->
        @i18next.t("common.tasks")

    uploadAttachmentMethod: "uploadTaskAttachment"
    getAttachmentsMethod: "getTaskAttachments"
    getHistoricalMethod: "getTaskHistorical"
    objectIdAttribute: "taskId"

    initialize: ->
        @debounceMethods()

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
                    @loadTask().then () =>
                        @onRemoveUrl = "/project/#{@scope.projectSlug}/taskboard/#{@scope.task.milestone_slug}"
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

    loadTask: ->
        @rs.getTask(@scope.projectId, @scope.taskId).then (task) =>
            @scope.task = task
            @scope.form = _.extend({}, @scope.task._attrs)

            breadcrumb = _.clone(@rootScope.pageBreadcrumb)
            breadcrumb[1] = [
                @i18next.t('common.tasks'),
                @rootScope.urls.taskboardUrl(@rootScope.projectSlug, @scope.task.milestone_slug)
            ]
            breadcrumb[2] = ["##{task.ref}", null]
            @rootScope.pageTitle = "#{@i18next.t("common.tasks")} - ##{task.ref}"

            @rootScope.pageBreadcrumb = breadcrumb

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

        return promise


moduleDeps = ['gmConfirm', 'taiga.services.resource', "taiga.services.data",
              "gmFlash", "i18next", "favico", "taiga.services.selectOptions"]
module = angular.module("taiga.controllers.tasks", moduleDeps)
module.controller("TasksViewController", TasksViewController)
