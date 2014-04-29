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


class SiteAdminController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                 "$model", "resource", "$confirm", "$location", "$i18next",
                 "$gmConfig", "$gmUrls", "$favico", "$q"]
    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @gmConfig, @gmUrls,
                  @favico, @q) ->
        super(scope, rootScope, favico)

    section: 'admin'
    getTitle: ->
        @i18next.t('common.admin-panel')

    initialize: ->
        @rootScope.pageBreadcrumb = [
            [@i18next.t('common.administer-site'), null],
        ]

        @scope.activeTab = "data"

        @scope.languageOptions = @gmConfig.get("languageOptions")

        @scope.addProjectFormOpened = false
        @scope.newProjectName = ""
        @scope.newProjectDescription = ""
        @scope.newProjectSprints = ""
        @scope.newProjectPoints = ""

        @loadMembers()
        @loadSite()

    isActive: (type) ->
        return type == @scope.activeTab

    setActive: (type) ->
        @scope.activeTab = type

    setMemberAs: (mbr, role) ->
        if role == 'owner'
            mbr.is_owner = true
            mbr.is_staff = true
        else if role == 'staff'
            mbr.is_owner = false
            mbr.is_staff = true
        else if role == 'normal'
            mbr.is_owner = false
            mbr.is_staff = false
        else
            throw new Error('invalid role')

        promise = mbr.save()
        promise.then =>
            @gmFlash.info(@i18next.t("admin-site.role-changed"))

        promise.then null, =>
            mbr.revert()
            @gmFlash.error(@i18next.t("admin-site.error-changing-the-role"))

        return promise

    submit: ->
        extraParams = {
            url: "#{@gmUrls.api('sites')}",
            method: "POST"
        }

        promise = @scope.currentSite.save(false, extraParams)
        promise.then (data) =>
            @gmFlash.info(@i18next.t("admin-site.saved-success"))
            @scope.site.data = data
            @rootScope.$broadcast('i18n:change')

        promise.then null, (data) =>
            @scope.checksleyErrors = data

        return promise

    deleteProject: (project) ->
        promise = @confirm.confirm(@i18next.t('common.are-you-sure'))
        promise.then =>
            @model.make_model('site-projects', project).remove().then =>
                @loadSite()
        return promise

    openNewProjectForm: ->
        @scope.addProjectFormOpened = true
        @scope.newProjectName = ""
        @scope.newProjectDescription = ""
        @scope.newProjectSprints = ""
        @scope.newProjectPoints = ""

    closeNewProjectForm: ->
        @scope.addProjectFormOpened = false

    toggleCreateTemplateProjectForm: (pr) ->
        if pr.createTemplateFormOpened?
            pr.createTemplateFormOpened = not pr.createTemplateFormOpened
        else
            pr.createTemplateFormOpened = true

    createTemplateFromProject: (pr) ->
        promise = @rs.createProjectTemplateFromProject(pr.id, pr.templateName, pr.templateDescription)
        promise.then (template) =>
            @gmFlash.info(@i18next.t("admin-site.template-created"))
            @rs.getProjectTemplates().then (templates) =>
                @scope.projectTemplates = templates
        promise.then null, =>
            @gmFlash.error(@i18next.t("admin-site.error-creating-template"))

    submitProject: ->
        projectData = {
            name: @scope.newProjectName,
            description: @scope.newProjectDescription,
            total_story_points: @scope.newProjectPoints
            total_milestones: @scope.newProjectSprints
        }
        promise = @rs.createProject(projectData, @scope.newProjectTemplate)
        promise.then =>
            @gmFlash.info(@i18next.t("admin-site.project-created"))
            @scope.addProjectFormOpened = false
            @loadSite()
        promise.then null, =>
            @gmFlash.error(@i18next.t("admin-site.error-creating-project"))
        return promise

    loadMembers: ->
        @rs.getSiteMembers().then (members) =>
            @scope.members = members

    loadSite: ->
        defered = @q.defer()

        @rs.getSite().then (site) =>
            @scope.currentSite = site
            @rs.getProjectTemplates().then (templates) =>
                @scope.projectTemplates = templates
                if not @scope.newProjectTemplate
                    @scope.newProjectTemplate = @scope.currentSite.default_project_template
                defered.resolve()
        return defered.promise


moduleDeps = ["taiga.services.data", "gmFlash", "taiga.services.model",
              "taiga.services.resource", "gmConfirm", "i18next", "gmConfig",
              "gmUrls", "favico"]
module = angular.module("taiga.controllers.site", moduleDeps)
module.controller("SiteAdminController", SiteAdminController)
