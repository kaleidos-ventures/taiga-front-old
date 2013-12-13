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

ProjectListController = ($scope, $rootScope, rs, $i18next) ->
    $rootScope.pageTitle = $i18next.t('common.dashboard')
    $rootScope.pageSection = 'projects'
    $rootScope.pageBreadcrumb = [
        ["Greenmine", $rootScope.urls.projectsUrl()],
        [$i18next.t('common.dashboard'), null]
    ]
    $rootScope.projectId = null

    rs.getProjects().then (projects) ->
        $scope.projects = projects

    return


ProjectAdminController = ($scope, $rootScope, $routeParams, $data, $gmFlash, $model,
                          rs, $confirm, $location, $i18next) ->
    $rootScope.pageTitle = $i18next.t('common.admin-panel')
    $rootScope.pageSection = 'admin'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t('common.admin-panel'), null]
    ]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.activeTab = "data"

    $scope.isActive = (type) ->
        return type == $scope.activeTab

    $scope.setActive = (type) ->
        $scope.activeTab = type

    # This attach "project" to $scope
    $data.loadProject($scope).then ->
        $data.loadUsersAndRoles($scope)

    $scope.submit = ->
        promise = $scope.project.save()
        promise.then (data) ->
            $gmFlash.info($i18next.t("projects.saved-success"))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.deleteProject = ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $scope.project.remove().then ->
                $location.url("/")

    $scope.deleteMilestone = (milestone) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $model.make_model('milestones', milestone).remove().then () ->
                $data.loadProject($scope)

    $scope.deleteMember = (member) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))
        promise.then () ->
            memberModel = $model.make_model("memberships", member)
            memberModel.remove().then ->
                $data.loadProject($scope)

    $scope.updateMemberRole = (member, roleId) ->
        memberModel = $model.make_model('memberships',member)
        memberModel.role = roleId
        memberModel.save().then (data) ->
            $data.loadProject($scope)

    $scope.memberStatus = (member) ->
        if member.user != null
            return "Active"
        else
            return "Inactive"

    $scope.memberName = (member) ->
        if member.full_name
            return member.full_name
        return ""

    $scope.memberEmail = (member) ->
        if member.user and $scope.constants.users[member.user]
            return $scope.constants.users[member.user].email
        return member.email

    $scope.formOpened = false

    $scope.toggleForm = ->
        if $scope.formOpened
            $scope.closeForm()
        else
            $scope.openForm()

    $scope.openForm = ->
        $scope.membership = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.submitMembership = ->
        promise = rs.createMembership($scope.membership)

        promise.then (data) ->
            $data.loadProject($scope)
            $data.loadUsersAndRoles($scope)
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    return


MembershipsController = ($scope, $rootScope, $model, $confirm, $i18next) ->
    $scope.deleteMember = (member) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))
        promise.then () ->
            $model.make_model('memberships',member).remove().then () ->
                $rootScope.$broadcast("membership:load-project")

    return

ShowProjectsController = ($scope, $rootScope, $model, rs) ->
    $scope.loading = false
    $scope.showingProjects = false
    $scope.myProjects = []
    $scope.showProjects = ->
        $scope.loading = true
        $scope.showingProjects = true

        rs.getProjects().then (projects) ->
            $scope.myProjects = projects
            $scope.loading = false

        rs.getProjects().then null, ->
            $scope.myProjects = []
            $scope.loading = false

    return


UserStoryStatusesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                                    $location, $i18next) ->
    $scope.status = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.status = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createUserStoryStatus($scope.status)

        promise.then (data) ->
            loadUserStoryStatuses()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadUserStoryStatuses = ->
        rs.getUserStoryStatuses($rootScope.projectId).then (data) ->
            $scope.userStoryStatuses = data

    resortUserStoryStatuses = ->
        saveChangedOrder = ->
            for item, index in $scope.userStoryStatuses
                item.order = index

            modifiedObjs = _.filter($scope.userStoryStatuses, (x) -> x.isModified())
            bulkData = _.map($scope.userStoryStatuses, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkUserStoryStatusesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("userstory-statuses:refresh", loadUserStoryStatuses)
    $scope.$on("sortable:changed", resortUserStoryStatuses)

    loadUserStoryStatuses()


UserStoryStatusController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                             $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("userstory-statuses:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


PointsAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                         $location, $i18next) ->
    $scope.point = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.point = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createPoints($scope.point)

        promise.then (data) ->
            loadPoints()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                loadPoints()

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)

    loadPoints = ->
        rs.getPoints($rootScope.projectId).then (data) ->
            $scope.points = data

    resortPoints = ->
        saveChangedOrder = ->
            for item, index in $scope.points
                item.order = index

            modifiedObjs = _.filter($scope.points, (x) -> x.isModified())
            bulkData = _.map($scope.points, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkPointsOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("points:refresh", loadPoints)
    $scope.$on("sortable:changed", resortPoints)

    loadPoints()


PointsController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                    $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("points:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


TaskStatusesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                               $location, $i18next) ->
    $scope.status = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.status = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createTaskStatus($scope.status)

        promise.then (data) ->
            loadTaskStatuses()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadTaskStatuses = ->
        rs.getTaskStatuses($rootScope.projectId).then (data) ->
            $scope.taskStatuses = data

    resortTaskStatuses = ->
        saveChangedOrder = ->
            for item, index in $scope.taskStatuses
                item.order = index

            modifiedObjs = _.filter($scope.taskStatuses, (x) -> x.isModified())
            bulkData = _.map($scope.taskStatuses, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkTaskStatusesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("task-statuses:refresh", loadTaskStatuses)
    $scope.$on("sortable:changed", resortTaskStatuses)

    loadTaskStatuses()


TaskStatusController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                        $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("task-statuses:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


IssueStatusesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                                $location, $i18next) ->
    $scope.status = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.status = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createIssueStatus($scope.status)

        promise.then (data) ->
            loadIssueStatuses()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadIssueStatuses = ->
        rs.getIssueStatuses($rootScope.projectId).then (data) ->
            $scope.issueStatuses = data

    resortIssueStatuses = ->
        saveChangedOrder = ->
            for item, index in $scope.issueStatuses
                item.order = index

            modifiedObjs = _.filter($scope.issueStatuses, (x) -> x.isModified())
            bulkData = _.map($scope.issueStatuses, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkIssueStatusesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("issue-statuses:refresh", loadIssueStatuses)
    $scope.$on("sortable:changed", resortIssueStatuses)

    loadIssueStatuses()


IssueStatusController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                         $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("issue-statuses:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


IssueTypesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                             $location, $i18next) ->
    $scope.type = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.type = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createIssueType($scope.type)

        promise.then (data) ->
            loadIssueTypes()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadIssueTypes = ->
        rs.getIssueTypes($rootScope.projectId).then (data) ->
            $scope.issueTypes = data

    resortIssueTypes = ->
        saveChangedOrder = ->
            for item, index in $scope.issueTypes
                item.order = index

            modifiedObjs = _.filter($scope.issueTypes, (x) -> x.isModified())
            bulkData = _.map($scope.issueTypes, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkIssueTypesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("issue-types:refresh", loadIssueTypes)
    $scope.$on("sortable:changed", resortIssueTypes)

    loadIssueTypes()


IssueTypeController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                       $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("issue-types:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


PrioritiesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                             $location, $i18next) ->
    $scope.priority = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.priority = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createPriority($scope.priority)

        promise.then (data) ->
            loadPriorities()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadPriorities = ->
        rs.getPriorities($rootScope.projectId).then (data) ->
            $scope.priorities = data

    resortPriorities = ->
        saveChangedOrder = ->
            for item, index in $scope.priorities
                item.order = index

            modifiedObjs = _.filter($scope.priorities, (x) -> x.isModified())
            bulkData = _.map($scope.priorities, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkPrioritiesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("priorities:refresh", loadPriorities)
    $scope.$on("sortable:changed", resortPriorities)

    loadPriorities()


PriorityController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                      $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("priorities:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


SeveritiesAdminController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                             $location, $i18next) ->
    $scope.severity = {}
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.severity = {project: $rootScope.projectId}
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = ->
        $scope.formOpened = false

    $scope.create = ->
        promise = rs.createSeverity($scope.severity)

        promise.then (data) ->
            loadSeverities()
            $scope.closeForm()

        promise.then null, (data) ->
            if data._error_message
                $gmFlash.error(data._error_message, false)
            $scope.checksleyErrors = data

    loadSeverities = ->
        rs.getSeverities($rootScope.projectId).then (data) ->
            $scope.severities = data

    resortSeverities = ->
        saveChangedOrder = ->
            for item, index in $scope.severities
                item.order = index

            modifiedObjs = _.filter($scope.severities, (x) -> x.isModified())
            bulkData = _.map($scope.severities, (value, index) -> [value.id, index])

            for item in modifiedObjs
                item._moving = true

            promise = rs.updateBulkSeveritiesOrder($scope.projectId, bulkData)
            promise = promise.then ->
                for obj in modifiedObjs
                    obj.markSaved()
                    obj._moving = false

            return promise
        # TODO
        #saveChangedOrder()

    $scope.$on("severities:refresh", loadSeverities)
    $scope.$on("sortable:changed", resortSeverities)

    loadSeverities()


SeverityController = ($scope, $rootScope, $routeParams, $gmFlash, $model, rs, $confirm,
                             $location, $i18next) ->
    $scope.formOpened = false

    $scope.openForm = ->
        $scope.$broadcast("checksley:reset")
        $scope.formOpened = true

    $scope.closeForm = (object) ->
        object.refresh()
        $scope.formOpened = false

    $scope.update = (object) ->
        object.save().then ->
            $scope.closeForm(object)

    $scope.delete = (object) ->
        promise = $confirm.confirm($i18next.t("common.are-you-sure"))

        promise.then () ->
            object.remove().then () ->
                $scope.$emit("severities:refresh")

        promise.then null, (data) ->
            $gmFlash.error($i18next.t("common.error-on-delete"), false)


module = angular.module("greenmine.controllers.project", [])
module.controller("ProjectListController", ['$scope', '$rootScope', 'resource', '$i18next',
                                            ProjectListController])
module.controller("ProjectAdminController", ["$scope", "$rootScope", "$routeParams", "$data",
                                             "$gmFlash", "$model", "resource", "$confirm", "$location",
                                             '$i18next', ProjectAdminController])
module.controller("MembershipsController", ["$scope", "$rootScope", "$model", "$confirm", "$i18next",
                                            MembershipsController])
module.controller("ShowProjectsController", ["$scope", "$rootScope", "$model", 'resource', ShowProjectsController])

module.controller("UserStoryStatusesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                       "$gmFlash", "$model", "resource", "$confirm",
                                                       "$location", '$i18next',
                                                       UserStoryStatusesAdminController])
module.controller("UserStoryStatusController", ["$scope", "$rootScope", "$routeParams",
                                                "$gmFlash", "$model", "resource", "$confirm",
                                                "$location", '$i18next',
                                                UserStoryStatusController])
module.controller("PointsAdminController", ["$scope", "$rootScope", "$routeParams",
                                            "$gmFlash", "$model", "resource", "$confirm",
                                            "$location", '$i18next',
                                            PointsAdminController])
module.controller("PointsController", ["$scope", "$rootScope", "$routeParams",
                                       "$gmFlash", "$model", "resource", "$confirm",
                                       "$location", '$i18next',
                                       PointsController])
module.controller("TaskStatusesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                  "$gmFlash", "$model", "resource", "$confirm",
                                                  "$location", '$i18next',
                                                  TaskStatusesAdminController])
module.controller("TaskStatusController", ["$scope", "$rootScope", "$routeParams",
                                           "$gmFlash", "$model", "resource", "$confirm",
                                           "$location", '$i18next',
                                           TaskStatusController])
module.controller("IssueStatusesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                   "$gmFlash", "$model", "resource", "$confirm",
                                                   "$location", '$i18next',
                                                   IssueStatusesAdminController])
module.controller("IssueStatusController", ["$scope", "$rootScope", "$routeParams",
                                            "$gmFlash", "$model", "resource", "$confirm",
                                            "$location", '$i18next',
                                            IssueStatusController])
module.controller("IssueTypesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                "$gmFlash", "$model", "resource", "$confirm",
                                                "$location", '$i18next',
                                                IssueTypesAdminController])
module.controller("IssueTypeController", ["$scope", "$rootScope", "$routeParams",
                                          "$gmFlash", "$model", "resource", "$confirm",
                                          "$location", '$i18next',
                                          IssueTypeController])
module.controller("PrioritiesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                "$gmFlash", "$model", "resource", "$confirm",
                                                "$location", '$i18next',
                                                PrioritiesAdminController])
module.controller("PriorityController", ["$scope", "$rootScope", "$routeParams",
                                         "$gmFlash", "$model", "resource", "$confirm",
                                         "$location", '$i18next',
                                         PriorityController])
module.controller("SeveritiesAdminController", ["$scope", "$rootScope", "$routeParams",
                                                "$gmFlash", "$model", "resource", "$confirm",
                                                "$location", '$i18next',
                                                SeveritiesAdminController])
module.controller("SeverityController", ["$scope", "$rootScope", "$routeParams",
                                         "$gmFlash", "$model", "resource", "$confirm",
                                         "$location", '$i18next',
                                         SeverityController])
