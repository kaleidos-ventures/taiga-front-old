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


TasksViewController = ($scope, $location, $rootScope, $routeParams, $q, $confirm, rs, $data, $gmFlash, $i18next) ->
    $rootScope.pageSection = 'tasks'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t("common.tasks"), null],
    ]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    taskId = $routeParams.taskid

    $scope.task = {}
    $scope.form = {}
    $scope.updateFormOpened = false
    $scope.newAttachments = []
    $scope.attachments = []

    loadAttachments = ->
        rs.getTaskAttachments(projectId, taskId).then (attachments) ->
            $scope.attachments = attachments

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    loadTask = ->
        rs.getTask(projectId, taskId).then (task) ->
            $scope.task = task
            $scope.form = _.extend({}, $scope.task._attrs)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[1] = [$i18next.t('common.taskboard'), $rootScope.urls.taskboardUrl($rootScope.projectId, $scope.task.milestone)]
            breadcrumb[2] = ["##{task.ref}", null]

            $rootScope.pageBreadcrumb = breadcrumb

    loadHistorical = (page=1) ->
        rs.getTaskHistorical(taskId, {page: page}).then (historical) ->
            if $scope.historical and page != 1
                historical.models = $scope.historical.models.concat(historical.models)

            $scope.showMoreHistoricaButton = historical.models.length < historical.count
            $scope.historical = historical

    $scope.loadMoreHistorical = ->
        page = if $scope.historical then $scope.historical.current + 1 else 1
        loadHistorical(page=page)

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attachment in $scope.newAttachments
            promise = rs.uploadTaskAttachment(projectId, taskId, attachment)
            promises.push(promise)

        promise = Q.all(promises)
        promise.then ->
            gm.safeApply $scope, ->
                $scope.newAttachments = []
                loadAttachments()

    # Load initial data
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope).then ->
            loadTask()
            loadAttachments()
            loadHistorical()
            loadProjectTags()

    $scope.isSameAs = (property, id) ->
        return ($scope.task[property] == parseInt(id, 10))

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        $scope.$emit("spinner:start")
        for key, value of $scope.form
            $scope.task[key] = value

        promise = $scope.task.save()
        promise.then (task) ->
            $scope.$emit("spinner:stop")
            saveNewAttachments()
            loadTask()
            loadHistorical()
            $gmFlash.info($i18next.t("task.task-saved"))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.removeAttachment = (attachment) ->
        promise = $confirm.confirm($i18next.t("task.are-you-sure"))
        promise.then () ->
            $scope.attachments = _.without($scope.attachments, attachment)
            attachment.remove()

    $scope.removeNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)

    $scope.removeTask = (task) ->
        promise = $confirm.confirm($i18next.t("task.are-you-sure"))
        promise.then ->
            milestone = task.milestone
            task.remove().then ->
                $location.url("/project/#{projectId}/taskboard/#{milestone}")

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value


module = angular.module("greenmine.controllers.tasks", [])
module.controller("TasksViewController", ['$scope', '$location', '$rootScope', '$routeParams', '$q', '$confirm', 'resource', "$data", "$gmFlash", "$i18next", TasksViewController])
