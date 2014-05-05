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
        @scope.$emit("history:reload")

        for key, value of @scope.form
            @scope.task[key] = value

        promise = @scope.task.save()
        promise.then (task) =>
            @gmFlash.info(@i18next.t("task.task-saved"))
            @scope.$emit("spinner:stop")
            @scope.$emit("history:reload")
            @.saveNewAttachments()
            @.loadTask()

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise


moduleDeps = ['gmConfirm', 'taiga.services.resource', "taiga.services.data",
              "gmFlash", "i18next", "favico", "taiga.services.selectOptions"]
module = angular.module("taiga.controllers.tasks", moduleDeps)
module.controller("TasksViewController", TasksViewController)
