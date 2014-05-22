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


class ProjectListController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', 'resource', '$i18next', '$favico']

    constructor: (@scope, @rootScope, @rs, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'projects'
    getTitle: ->
        @i18next.t('common.dashboard')

    initialize: ->
        @rootScope.projectSlug = undefined
        @rootScope.pageBreadcrumb = [
            ["Taiga", @rootScope.urls.projectsUrl()],
            [@i18next.t('common.dashboard'), null]
        ]
        @rootScope.projectId = null

        @rs.getProjects().then (projects) =>
            @scope.projects = projects


class ShowProjectsController extends TaigaBaseController
    @.$inject = ["$scope", "$rootScope", "$model", 'resource']
    constructor: (@scope, @rootScope, @model, @rs) ->
        super(scope)

    initialize: ->
        @scope.loading = false
        @scope.showingProjects = false
        @scope.myProjects = []
        @scope.showProjects = =>
            @scope.loading = true
            @scope.showingProjects = true

            promise = @rs.getProjects()

            promise.then (projects) =>
                @scope.myProjects = projects
                @scope.loading = false

            promise.then null, =>
                @scope.myProjects = []
                @scope.loading = false


class ProjectAdminController extends TaigaPageController
    constructor: (@scope, @rootScope, @routeParams, @data, @rs, @i18next, @favico, @location) ->
        super(scope, rootScope, favico)

    section: 'admin'
    getTitle: ->
        @i18next.t('common.admin-panel')

    initialize: ->
        @rootScope.pageSection = 'admin'
        @rootScope.pageBreadcrumb = [
            ["", ""],
            [@i18next.t('common.admin-panel'), null]
        ]
        @rs.resolve({pslug: @routeParams.pslug}).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @data.loadProject(@scope)

    isActive: (type) ->
        return type == @activeTab

    goTo: (section) ->
        @location.url(@rootScope.urls.adminUrl(@routeParams.pslug, section, true))

class ProjectAdminMainController extends ProjectAdminController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                "$model", "resource", "$confirm", "$location", '$i18next',
                '$q', '$favico']

    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @q, @favico) ->
        super(scope, rootScope, routeParams, data, rs, i18next, favico, location)

    activeTab: 'main'

    submit: ->
        promise = @scope.project.save()
        promise.then (data) =>
            @gmFlash.info(@i18next.t("projects.saved-success"))

        promise.then null, (data) =>
            @scope.checksleyErrors = data


class ProjectAdminValuesController extends ProjectAdminController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                "$model", "resource", "$confirm", "$location", '$i18next',
                '$q', '$favico']

    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @q, @favico) ->
        super(scope, rootScope, routeParams, data, rs, i18next, favico, location)

    activeTab: "values"

    initialize: ->
        super().then =>
            @scope.$broadcast('project:loaded')


class ProjectAdminMilestonesController extends ProjectAdminController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                "$model", "resource", "$confirm", "$location", '$i18next',
                '$q', '$favico']

    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @q, @favico) ->
        super(scope, rootScope, routeParams, data, rs, i18next, favico, location)

    activeTab: "milestones"

    initialize: ->
        super().then =>
            @rs.getMilestones(@rootScope.projectId).then (data) =>
                @scope.milestones = data

    deleteMilestone: (milestone) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () =>
            milestone.remove().then () =>
                _.remove(@scope.milestones, milestone)

class ProjectAdminMembershipsController extends ProjectAdminController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                "$model", "resource", "$confirm", "$location", '$i18next',
                '$q', '$favico']

    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @q, @favico) ->
        super(scope, rootScope, routeParams, data, rs, i18next, favico, location)

    activeTab: "memberships"

    initialize: ->
        super().then =>
            @data.loadUsersAndRoles(@scope)
        @scope.formOpened = false

    toggleForm: ->
        if @scope.formOpened
            @closeForm()
        else
            @openForm()

    openForm: ->
        @scope.membership = {project: @rootScope.projectId}
        @scope.$broadcast("checksley:reset")
        @scope.formOpened = true

    closeForm: ->
        @scope.formOpened = false

    submitMembership: ->
        promise = @rs.createMembership(@scope.membership)

        promise.then (data) =>
            @data.loadProject(@scope)
            @data.loadUsersAndRoles(@scope)
            @closeForm()

        promise.then null, (data) =>
            if data._error_message
                @gmFlash.error(data._error_message)
            @scope.checksleyErrors = data

    memberStatus: (member) ->
        if member?.user != null
            return @i18next.t('admin.active')
        else
            return @i18next.t('admin.inactive')

    memberName: (member) ->
        return member?.full_name

    memberEmail: (member) ->
        if member?.user and @scope.constants.users[member.user]
            return @scope.constants.users[member.user].email
        return member?.email

    deleteMember: (member) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then () =>
            memberModel = @model.make_model("memberships", member)
            memberModel.remove().then =>
                @data.loadProject(@scope)

    updateMemberRole: (member, roleId) ->
        memberModel = @model.make_model('memberships',member)
        memberModel.role = roleId
        memberModel.save().then (data) =>
            @data.loadProject(@scope)

    getAbsoluteUrl: (url) ->
        if @location.protocol() == "http" and @location.port() != 80
            return "#{@location.protocol()}://#{@location.host()}:#{@location.port()}#{url}"
        else if @location.protocol() == "https" and @location.port() != 443
            return "#{@location.protocol()}://#{@location.host()}:#{@location.port()}#{url}"
        else
            return "#{@location.protocol()}://#{@location.host()}#{url}"


class ProjectAdminRolesController extends ProjectAdminController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                "$model", "resource", "$confirm", "$location", '$i18next',
                '$q', '$favico']

    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @q, @favico) ->
        super(scope, rootScope, routeParams, data, rs, i18next, favico, location)

    activeTab: "roles"

    initialize: ->
        @scope.showPermissions = []
        @scope.rolePermissions = {}
        @scope.newRole = {}
        @scope.newRolePermissions = {}
        @data.loadPermissions()
        super().then =>
            @loadRoles()

    loadRoles: =>
        if @scope.project?
            @data.loadUsersAndRoles(@scope).then =>
                for role in @rootScope.constants.rolesList
                    @scope.rolePermissions[role.id] = {}
                    for permission in @rootScope.constants.permissionsList
                        @scope.rolePermissions[role.id][permission.id] = permission.id in role.permissions
                for permission in @rootScope.constants.permissionsList
                    @scope.newRolePermissions[permission.id] = false

    submitRoles: ->
        promises = []

        if @scope.newRole.name
            permissions = _.pairs(@scope.newRolePermissions)
            permissions = _.filter(permissions, (permission) -> permission[1])
            permissions = _.map(permissions, (permission) -> permission[0].toString())
            @scope.newRole.permissions = permissions

            creationPromise = @rs.createRole(@rootScope.projectId, @scope.newRole).then (data) =>
                @loadRoles().then =>
                    @scope.newRole = {}
                    @scope.showNewRole = false
                    @scope.newRolePermissions = []

            promises.push creationPromise

        for role, index in @scope.constants.rolesList
            permissions = _.pairs(@scope.rolePermissions[role.id])
            permissions = _.filter(permissions, (permission) -> permission[1])
            permissions = _.map(permissions, (permission) -> permission[0].toString())
            permissions.sort()
            currentPermissions = _.map(role.permissions, (permission) -> permission.toString())
            currentPermissions.sort()

            if role.order != index
                role.order = index

            if not _.isEqual(currentPermissions, permissions)
                role.permissions = permissions
            promises.push(role.save())

        allPromises = @q.all(promises)
        allPromises.then =>
            @gmFlash.info(@i18next.t("admin.roles-saved-success"))

        allPromises.then null, (data) =>
            @scope.checksleyErrors = data

    deleteRole: (role) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then () =>
            role.remove().then () =>
                @loadRoles().then =>
                    @gmFlash.info(@i18next.t("admin.role-deleted"))

    sortableOnUpdate: (roles) ->
        @scope.constants.rolesList = roles


class ChoicesAdminController extends TaigaBaseController
    @.$inject = ["$scope", "$rootScope", "$gmFlash", "resource"]

    constructor: (@scope, @rootScope, @gmFlash, @rs) ->
        super(scope)

    initialize: ->
        @scope[@instanceModel] = {}
        @scope.formOpened = false
        @scope.$on(@refreshEvent, @loadData)
        @scope.$on('project:loaded', @loadData)

    openForm: ->
        @scope[@instanceModel] = {project: @rootScope.projectId}
        @scope.$broadcast("checksley:reset")
        @scope.formOpened = true

    closeForm: ->
        @scope.formOpened = false

    create: ->
        promise = @createInstance()

        promise.then (data) =>
            @loadData()
            @closeForm()

        promise.then null, (data) =>
            if data._error_message
                @gmFlash.error(data._error_message)
            @scope.checksleyErrors = data

    resort: (model) ->
        for item, index in @scope[model]
            item.order = index

        modifiedObjs = _.filter(@scope[model], (x) -> x.isModified())
        bulkData = _.map(@scope[model], (value, index) -> [value.id, index])

        for item in modifiedObjs
            item._moving = true

        promise = @bulkUpdate(bulkData)
        promise = promise.then ->
            for obj in modifiedObjs
                obj.markSaved()
                obj._moving = false

        return promise

    sortableOnUpdate: (items) ->
        @scope[@model] = items
        @resort(@model)

class ChoiceController extends TaigaBaseController
    @.$inject = ["$scope", "$gmFlash", "resource", "$confirm", "$i18next"]
    refreshEvent: "choices:refresh"

    constructor: (@scope, @gmFlash, @rs, @confirm, @i18next) ->
        super(scope)

    initialize: ->
        @scope.formOpened = false

    openForm: ->
        @scope.$broadcast("checksley:reset")
        @scope.formOpened = true

    closeForm: (object) ->
        object.refresh()
        @scope.formOpened = false

    update: (object) ->
        object.save().then =>
            @closeForm(object)

    delete: (object) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))

        promise.then () =>
            onSuccess = =>
                @scope.$emit(@refreshEvent)

            onError = =>
                @gmFlash.error(@i18next.t("common.error-on-delete"))

            promise = object.remove().then(onSuccess, onError)


class UserStoryStatusesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "userStoryStatuses"
    instanceModel: "status"
    createInstance: ->
        @rs.createUserStoryStatus(@scope[@instanceModel])

    loadData: =>
        @rs.getUserStoryStatuses(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkUserStoryStatusesOrder(@scope.projectId, bulkData)


class PointsAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "points"
    instanceModel: "point"
    createInstance: ->
        @rs.createPoints(@scope[@instanceModel])

    loadData: =>
        @rs.getPoints(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkPointsOrder(@scope.projectId, bulkData)


class TaskStatusesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "taskStatuses"
    instanceModel: "status"
    createInstance: ->
        @rs.createTaskStatus(@scope[@instanceModel])

    loadData: =>
        @rs.getTaskStatuses(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkTaskStatusesOrder(@scope.projectId, bulkData)


class IssueStatusesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "issueStatuses"
    instanceModel: "status"
    createInstance: ->
        @rs.createIssueStatus(@scope[@instanceModel])

    loadData: =>
        @rs.getIssueStatuses(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkIssueStatusesOrder(@scope.projectId, bulkData)


class IssueTypesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "issueTypes"
    instanceModel: "type"
    createInstance: ->
        @rs.createIssueType(@scope[@instanceModel])

    loadData: =>
        @rs.getIssueTypes(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkIssueTypesOrder(@scope.projectId, bulkData)


class PrioritiesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "priorities"
    instanceModel: "priority"
    createInstance: ->
        @rs.createPriority(@scope[@instanceModel])

    loadData: =>
        @rs.getPriorities(@rootScope.projectId).then (data) =>
            @scope.priorities = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkPrioritiesOrder(@scope.projectId, bulkData)


class SeveritiesAdminController extends ChoicesAdminController
    refreshEvent: "choices:refresh"
    model: "severities"
    instanceModel: "severity"
    createInstance: ->
        @rs.createSeverity(@scope[@instanceModel])

    loadData: =>
        @rs.getSeverities(@rootScope.projectId).then (data) =>
            @scope[@model] = data

    bulkUpdate: (bulkData) =>
        @rs.updateBulkSeveritiesOrder(@scope.projectId, bulkData)


moduleDeps = ["taiga.services.data", "gmFlash", "taiga.services.model",
              "taiga.services.resource", "gmConfirm", 'i18next', 'favico']
module = angular.module("taiga.controllers.project", moduleDeps)
module.controller("ProjectListController", ProjectListController)
module.controller("ProjectAdminMainController",  ProjectAdminMainController)
module.controller("ProjectAdminValuesController", ProjectAdminValuesController)
module.controller("ProjectAdminMilestonesController", ProjectAdminMilestonesController)
module.controller("ProjectAdminRolesController", ProjectAdminRolesController)
module.controller("ProjectAdminMembershipsController", ProjectAdminMembershipsController)
module.controller("ShowProjectsController", ShowProjectsController)
module.controller("UserStoryStatusesAdminController", UserStoryStatusesAdminController)
module.controller("PointsAdminController", PointsAdminController)
module.controller("TaskStatusesAdminController", TaskStatusesAdminController)
module.controller("IssueStatusesAdminController", IssueStatusesAdminController)
module.controller("IssueTypesAdminController", IssueTypesAdminController)
module.controller("PrioritiesAdminController", PrioritiesAdminController)
module.controller("SeveritiesAdminController", SeveritiesAdminController)
module.controller("ChoiceController", ChoiceController)
