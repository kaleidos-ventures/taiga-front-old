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


@taiga = {}
@gm = @taiga

configure = ($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider, $gmUrlsProvider) ->
    $routeProvider.when('/',
        {templateUrl: '/partials/project-list.html', controller: "ProjectListController as ctrl"})

    $routeProvider.when('/login',
        {templateUrl: '/partials/login.html', controller: "LoginController as ctrl"})

    $routeProvider.when('/recovery',
        {templateUrl: '/partials/recovery.html', controller: "RecoveryController as ctrl"})

    $routeProvider.when('/change-password',
        {templateUrl: '/partials/change-password.html', controller: "ChangePasswordController as ctrl"})

    $routeProvider.when('/change-password/:token',
        {templateUrl: '/partials/change-password.html', controller: "ChangePasswordController as ctrl"})

    $routeProvider.when('/profile',
        {templateUrl: '/partials/profile.html', controller: "ProfileController as ctrl"})

    $routeProvider.when("/register",
        {controller: "PublicRegisterController as ctrl", templateUrl: "partials/register.html"})

    $routeProvider.when("/invitation/:token",
        {controller: "InvitationRegisterController as ctrl", templateUrl: "partials/invitation-register.html"})

    $routeProvider.when('/project/:pslug/backlog',
        {templateUrl: '/partials/backlog.html', controller: "BacklogController as ctrl"})

    $routeProvider.when('/project/:pslug/kanban',
        {templateUrl: '/partials/kanban.html', controller: "KanbanController as ctrl"})

    $routeProvider.when('/project/:pslug/user-story/:ref',
        {templateUrl: '/partials/user-story-view.html', controller: "UserStoryViewController as ctrl"})

    $routeProvider.when('/project/:pslug/issues',
        {templateUrl: '/partials/issues.html', controller: "IssuesController as ctrl"})

    $routeProvider.when('/project/:pslug/issues/:ref',
        {templateUrl: '/partials/issues-view.html', controller: "IssuesViewController as ctrl"})

    $routeProvider.when('/project/:pslug/tasks/:ref',
        {templateUrl: '/partials/tasks-view.html', controller: "TasksViewController as ctrl"})

    $routeProvider.when('/project/:pslug/taskboard/:sslug',
        {templateUrl: '/partials/taskboard.html', controller: "TaskboardController as ctrl"})

    $routeProvider.when('/wiki-help',
        {templateUrl: '/partials/wiki-help.html', controller: "WikiHelpController as ctrl"})

    $routeProvider.when('/project/:pslug/wiki/:slug',
        {templateUrl: '/partials/wiki.html', controller: "WikiController as ctrl"})

    $routeProvider.when('/project/:pslug/wiki/:slug/historical',
        {templateUrl: '/partials/wiki-historical.html', controller: "WikiHistoricalController as ctrl"})

    $routeProvider.when('/project/:pslug/search',
        {controller: "SearchController as ctrl", templateUrl: "/partials/search.html"})

    $routeProvider.when('/project/:pslug/admin/main',
        {controller: "ProjectAdminMainController as ctrl", templateUrl: "/partials/project-admin-main.html"})

    $routeProvider.when('/project/:pslug/admin/values',
        {controller: "ProjectAdminValuesController as ctrl", templateUrl: "/partials/project-admin-values.html"})

    $routeProvider.when('/project/:pslug/admin/milestones',
        {controller: "ProjectAdminMilestonesController as ctrl", templateUrl: "/partials/project-admin-milestones.html"})

    $routeProvider.when('/project/:pslug/admin/roles',
        {controller: "ProjectAdminRolesController as ctrl", templateUrl: "/partials/project-admin-roles.html"})

    $routeProvider.when('/project/:pslug/admin/memberships', {
        controller: "ProjectAdminMembershipsController as ctrl",
        templateUrl: "/partials/project-admin-memberships.html"
    })

    $routeProvider.when('/admin',
        {controller: "SiteAdminController as ctrl", templateUrl: "partials/site-admin.html"})

    $routeProvider.otherwise({redirectTo: '/login'})
    $locationProvider.html5Mode(true);

    defaultHeaders = {
        "Content-Type": "application/json"
        "Accept-Language": "en"
        "X-Host": window.location.hostname
    }

    $httpProvider.defaults.headers.delete = defaultHeaders
    $httpProvider.defaults.headers.patch = defaultHeaders
    $httpProvider.defaults.headers.post = defaultHeaders
    $httpProvider.defaults.headers.put = defaultHeaders
    $httpProvider.defaults.headers.get = {
        "X-Host": window.location.hostname
    }

    authHttpIntercept = ($q, $location) ->
        return (promise) ->
            return promise.then null, (response) ->
                if response.status == 401 or response.status == 0
                    $location.url("/login?next=#{$location.path()}")
                return $q.reject(response)

    $provide.factory("authHttpIntercept", ["$q", "$location", authHttpIntercept])
    $httpProvider.responseInterceptors.push('authHttpIntercept')

    apiUrls = {
        "auth": "/api/v1/auth"
        "auth-register": "/api/v1/auth/register"
        "permissions": "/api/v1/permissions"
        "roles": "/api/v1/roles"
        "projects": "/api/v1/projects"
        "memberships": "/api/v1/memberships"
        "milestones": "/api/v1/milestones"
        "userstories": "/api/v1/userstories"
        "bulk-create-us": "/api/v1/userstories/bulk_create"
        "bulk-update-us-order": "/api/v1/userstories/bulk_update_order"
        "userstories-restore": "/api/v1/userstories/%s/restore"
        "tasks": "/api/v1/tasks"
        "bulk-create-tasks": "/api/v1/tasks/bulk_create"
        "tasks-restore": "/api/v1/tasks/%s/restore"
        "issues": "/api/v1/issues"
        "issues-restore": "/api/v1/issues/%s/restore"
        "wiki": "/api/v1/wiki"
        "wiki-restore": "/api/v1/wiki/%s/restore"
        "choices/userstory-statuses": "/api/v1/userstory-statuses"
        "choices/userstory-statuses/bulk-update-order": "/api/v1/userstory-statuses/bulk_update_order"
        "choices/points": "/api/v1/points"
        "choices/points/bulk-update-order": "/api/v1/points/bulk_update_order"
        "choices/task-statuses": "/api/v1/task-statuses"
        "choices/task-statuses/bulk-update-order": "/api/v1/task-statuses/bulk_update_order"
        "choices/issue-statuses": "/api/v1/issue-statuses"
        "choices/issue-statuses/bulk-update-order": "/api/v1/issue-statuses/bulk_update_order"
        "choices/issue-types": "/api/v1/issue-types"
        "choices/issue-types/bulk-update-order": "/api/v1/issue-types/bulk_update_order"
        "choices/priorities": "/api/v1/priorities"
        "choices/priorities/bulk-update-order": "/api/v1/priorities/bulk_update_order"
        "choices/severities": "/api/v1/severities"
        "choices/severities/bulk-update-order": "/api/v1/severities/bulk_update_order"
        "search": "/api/v1/search"
        "sites": "/api/v1/sites"
        "project-templates": "/api/v1/project-templates"
        "site-members": "/api/v1/site-members"
        "site-projects": "/api/v1/site-projects"
        "users": "/api/v1/users"
        "users-password-recovery": "/api/v1/users/password_recovery"
        "users-change-password-from-recovery": "/api/v1/users/change_password_from_recovery"
        "users-change-password": "/api/v1/users/change_password"
        "resolver": "/api/v1/resolver"
        "wiki-attachment": "/media/attachment-files/%s/wikipage/%s"

        # History
        "history/userstory": "/api/v1/history/userstory"
        "history/issue": "/api/v1/history/issue"
        "history/task": "/api/v1/history/task"
        "history/wiki": "/api/v1/history/wiki"

        # Attachments
        "userstories/attachments": "/api/v1/userstories/attachments"
        "issues/attachments": "/api/v1/issues/attachments"
        "tasks/attachments": "/api/v1/tasks/attachments"
        "wiki/attachments": "/api/v1/wiki/attachments"
    }

    $gmUrlsProvider.setUrls("api", apiUrls)

assignInitialConstants = ($rootScope) ->
    $rootScope.pageTitle = ""
    $rootScope.constants = {}

    $rootScope.constants.usStatuses = {}
    $rootScope.constants.usStatusesList = []
    $rootScope.constants.points = {}
    $rootScope.constants.pointsList = []
    $rootScope.constants.pointsByOrder = {}

    $rootScope.constants.taskStatuses = {}
    $rootScope.constants.taskStatusesList = []

    $rootScope.constants.types = {}
    $rootScope.constants.typesList = []
    $rootScope.constants.severities = {}
    $rootScope.constants.severitiesList = []
    $rootScope.constants.priorities = {}
    $rootScope.constants.prioritiesList = []
    $rootScope.constants.issueStatuses = {}
    $rootScope.constants.issueStatusesList = []
    $rootScope.constants.issueTypes = {}
    $rootScope.constants.issueTypesList = []

    $rootScope.constants.permissionsList = []
    $rootScope.constants.permissionsGroups = {}

    $rootScope.constants.users = {}

assignNavegationUrls = ($rootScope, $gmUrls) ->
    conditionalUrl = (url, raw) ->
        return url if raw
        return "#{url}"

    $rootScope.baseUrls = {
        projects: "/"
        backlog: "/project/%s/backlog"
        kanban: "/project/%s/kanban"
        taskboard: "/project/%s/taskboard/%s"
        userstory: "/project/%s/user-story/%s"
        issue: "/project/%s/issues/%s"
        issues: "/project/%s/issues"
        task: "/project/%s/tasks/%s"
        tasks: "/project/%s/tasks/%s"
        wiki: "/project/%s/wiki/%s"
        wikiHelp: "/wiki-help"
        wikiHistorical: "/project/%s/wiki/%s/historical"
        search: "/project/%s/search"
        invitation: "/invitation/%s"
        admin: "/project/%s/admin/%s"
        attachment: "/media/attachment-files/%s/%s/%s"
    }

    $rootScope.urls =
        projectsUrl: ->
            return '/'

        projectHomeUrl: (project, raw) ->
            if project.is_backlog_activated
                return $rootScope.urls.backlogUrl(project.slug, raw)
            else if project.is_kanban_activated
                return $rootScope.urls.kanbanUrl(project.slug, raw)
            else if project.is_issues_activated
                return $rootScope.urls.issuesUrl(project.slug, raw)
            else if project.is_wiki_activated
                return $rootScope.urls.wikiUrl(project.slug, "home", raw)
            return $rootScope.urls.adminUrl(project.slug, null, raw)

        backlogUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.backlog, [projectId])
            return conditionalUrl(url, raw)

        kanbanUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.kanban, [projectId])
            return conditionalUrl(url, raw)

        taskboardUrl: (projectId, sprintId, raw) ->
            url = gm.format($rootScope.baseUrls.taskboard, [projectId, sprintId])
            return conditionalUrl(url, raw)

        userStoryUrl: (projectId, userStoryId, raw, params={}) ->
            url = gm.format($rootScope.baseUrls.userstory, [projectId, userStoryId])
            url = conditionalUrl(url, raw)
            if params isnt {}
                url = "#{url}?#{jQuery.param(params)}"
            return url

        adminUrl: (projectId, section, raw) ->
            url = gm.format($rootScope.baseUrls.admin, [projectId, section])
            return conditionalUrl(url, raw)

        issuesUrl: (projectId, issueId, raw, params={}) ->
            url = null

            if issueId != undefined
                url = gm.format($rootScope.baseUrls.issue, [projectId, issueId])
            else
                url = gm.format($rootScope.baseUrls.issues, [projectId])

            url =  conditionalUrl(url, raw)

            if params isnt {}
                url = "#{url}?#{jQuery.param(params)}"

            return url

        tasksUrl: (projectId, taskId, raw) ->
            url = null

            if taskId != undefined
                url = gm.format($rootScope.baseUrls.task, [projectId, taskId])
            else
                url = gm.format($rootScope.baseUrls.tasks, [projectId])

            return conditionalUrl(url, raw)

        wikiUrl: (projectId, pageName, raw) ->
            url = gm.format($rootScope.baseUrls.wiki, [projectId, pageName])
            return conditionalUrl(url, raw)

        wikiHistoricalUrl: (projectId, pageName, raw) ->
            url = gm.format($rootScope.baseUrls.wikiHistorical, [projectId, pageName])
            return conditionalUrl(url, raw)

        wikiHelpUrl: ->
            return conditionalUrl($rootScope.baseUrls.wikiHelp, false)

        searchUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.search, [projectId])
            return conditionalUrl(url, raw)

        invitationUrl: (token, raw) ->
            url = gm.format($rootScope.baseUrls.invitation, [token])
            return conditionalUrl(url, raw)

        attachmentUrl: (projectId, section, name) ->
            url = $gmUrls.api('wiki-attachment', projectId, name)
            return url

        videoConferenceUrl: (project) ->
            if not project?
                return ""

            if project.videoconferences == "appear-in"
                baseUrl = "https://appear.in/"
            else if project.videoconferences == "talky"
                baseUrl = "https://talky.io/"
            else
                return ""

            if project.videoconferences_salt
                url = "#{$rootScope.site.headers['x-site-host']}-#{project.slug}-#{project.videoconferences_salt}"
            else
                url = "#{$rootScope.site.headers['x-site-host']}-#{project.slug}"

            return baseUrl + url



init = ($rootScope, $location, $gmStorage, $gmAuth, $gmUrls, $i18next, $gmConfig, localconfig, $data, $log, $favico) ->
    $rootScope.auth = $gmAuth.getUser()

    # Assing to root scope intial empty constants
    assignInitialConstants($rootScope)

    # Assign navegration urls
    assignNavegationUrls($rootScope, $gmUrls)

    # Initialize configuration
    $gmConfig.initialize(localconfig)

    # Configure on init a default host and scheme for api urls.
    $gmUrls.setHost("api", $gmConfig.get("host"), $gmConfig.get("scheme"))

    # Initialize i18next service
    $i18next.initialize($gmConfig.get("defaultLanguage"))

    # Load site data.
    $data.loadSiteInfo($rootScope).then (sitedata) ->
        $log.debug "Site data:", sitedata

    # Overwrite debug logging function if loging is disabled
    # Is seems hacky but is the unque way at this momment.
    if not $gmConfig.get("debug")
        $log.debug = ->

    $rootScope.momentFormat = (input, format) ->
        return moment(input).format(format)

    $rootScope.logout = () ->
        $gmStorage.clear()
        $location.url("/login")

    # FIXME: the following next two event assignations
    # related to i18n seems need a refactor ;)

    $rootScope.$on "i18n:change", (event, lang) ->
        if lang
            newLang = lang
        else if $rootScope.auth.default_language
            newLang = $rootScope.auth.default_language
        else if $rootScope.site.data.default_language
            newLang = $rootScope.site.data.default_language
        else
            newLang = $gmConfig.get("defaultLanguage")

        $i18next.setLang(newLang)
        moment.lang(newLang)

    $rootScope.$on "i18next:changeLang", ->
        messages = {
            defaultMessage: $i18next.t('checksley.defaultMessage')
            type:
                email: $i18next.t('checksley.type-email')
                url: $i18next.t('checksley.type-url')
                urlstrict: $i18next.t('checksley.type-urlstrict')
                number: $i18next.t('checksley.type-number')
                digits: $i18next.t('checksley.type-digits')
                dateIso: $i18next.t('checksley.type-dateIso')
                alphanum: $i18next.t('checksley.type-alphanum')
                phone: $i18next.t('checksley.type-phone')
            notnull: $i18next.t('checksley.notnull')
            notblank: $i18next.t('checksley.notblank')
            required: $i18next.t('checksley.required')
            regexp: $i18next.t('checksley.regexp')
            min: $i18next.t('checksley.min')
            max: $i18next.t('checksley.max')
            range: $i18next.t('checksley.range')
            minlength: $i18next.t('checksley.minlength')
            maxlength: $i18next.t('checksley.maxlength')
            rangelength: $i18next.t('checksley.rangelength')
            mincheck: $i18next.t('checksley.mincheck')
            maxcheck: $i18next.t('checksley.maxcheck')
            rangecheck: $i18next.t('checksley.rangecheck')
            equalto: $i18next.t('checksley.equalto')
        }
        checksley.updateMessages('default', messages)

    $rootScope.$on "$routeChangeSuccess", ->
        $('html, body').scrollTop(0)

    $favico.newFavico()


modules = [
    "ngRoute",
    "ngAnimate",
    "ngSanitize",

    "taiga.controllers.auth",
    "taiga.controllers.backlog",
    "taiga.controllers.kanban",
    "taiga.controllers.user-story",
    "taiga.controllers.search",
    "taiga.controllers.taskboard",
    "taiga.controllers.issues",
    "taiga.controllers.project",
    "taiga.controllers.tasks",
    "taiga.controllers.wiki",
    "taiga.controllers.site",
    "taiga.filters",
    "taiga.services.data",
    "taiga.services.auth",
    "taiga.services.model",
    "taiga.services.resource",
    "taiga.services.filters",
    "taiga.directives.generic",
    "taiga.directives.common",
    "taiga.directives.graphs",
    "taiga.directives.history",
    "taiga.directives.backlog",
    "taiga.directives.issues",
    "taiga.directives.popovers",
    "taiga.localconfig",

    "coffeeColorPicker",

    # Plugins modules.
    "gmUrls",
    "gmFlash",
    "gmModal",
    "gmStorage",
    "gmConfirm",
    "gmOverlay",
    "gmConfig",
    "i18next",
    "favico",
    "ui.select2",
    "gmWiki"
]

init.$inject = ['$rootScope', '$location', '$gmStorage', '$gmAuth', '$gmUrls',
                '$i18next', '$gmConfig', 'localconfig', '$data', '$log', '$favico']

configure.$inject = ['$routeProvider', '$locationProvider', '$httpProvider',
                     '$provide', '$compileProvider', '$gmUrlsProvider']

angular.module("taiga.localconfig", []).value("localconfig", {})
angular.module('taiga', modules)
       .config(configure)
       .run(init)
