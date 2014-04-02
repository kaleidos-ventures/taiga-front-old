# Copyright 2013-2014 Andrey Antukh <niwi@niwi.be>
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

class SiteAdminController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "$gmFlash",
                 "$model", "resource", "$confirm", "$location", "$i18next",
                 "$gmConfig", "$gmUrls", "$favico"]
    constructor: (@scope, @rootScope, @routeParams, @data, @gmFlash, @model,
                  @rs, @confirm, @location, @i18next, @gmConfig, @gmUrls, @favico) ->
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

        @scope.addProjectFormOpened = true
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
            @gmFlash.info(@i18next.t("admin-site.error-creating-project"))
        return promise

    loadMembers: ->
        @rs.getSiteMembers().then (members) =>
            @scope.members = members

    loadSite: ->
        @rs.getSite().then (site) =>
            @scope.currentSite = site


moduleDeps = ["taiga.services.data", "gmFlash", "taiga.services.model",
              "taiga.services.resource", "gmConfirm", "i18next", "gmConfig",
              "gmUrls", "favico"]
module = angular.module("taiga.controllers.site", moduleDeps)
module.controller("SiteAdminController", SiteAdminController)
