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

@greenmine = {}
@gm = @greenmine

gm = @gm
gm.format = (fmt, obj, named) ->
    obj = _.clone(obj)
    if named
        return fmt.replace /%\(\w+\)s/g, (match) -> String(obj[match.slice(2,-2)])
    else
        return fmt.replace /%s/g, (match) -> String(obj.shift())

configCallback = ($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider, $gmUrlsProvider) ->
    $routeProvider.when('/',
        {templateUrl: 'partials/project-list.html', controller: "ProjectListController"})

    $routeProvider.when('/login',
        {templateUrl: 'partials/login.html', controller: "LoginController"})

    $routeProvider.when('/recovery',
        {templateUrl: 'partials/recovery.html', controller: "RecoveryController"})

    $routeProvider.when('/change-password',
        {templateUrl: 'partials/change-password.html', controller: "ChangePasswordController"})

    $routeProvider.when('/change-password/:token',
        {templateUrl: 'partials/change-password.html', controller: "ChangePasswordController"})

    $routeProvider.when('/profile',
        {templateUrl: 'partials/profile.html', controller: "ProfileController"})

    $routeProvider.when("/register",
        {controller: "PublicRegisterController", templateUrl: "partials/register.html"})

    $routeProvider.when("/invitation/:token", {
        controller: "InvitationRegisterController", templateUrl: "partials/invitation-register.html"})

    $routeProvider.when('/project/:pid/backlog',
            {templateUrl: 'partials/backlog.html', controller: "BacklogController"})

    $routeProvider.when('/project/:pid/user-story/:userstoryid',
            {templateUrl: 'partials/user-story-view.html', controller: "UserStoryViewController"})

    $routeProvider.when('/project/:pid/issues',
            {templateUrl: 'partials/issues.html', controller: "IssuesController"})

    $routeProvider.when('/project/:pid/issues/:issueid',
            {templateUrl: 'partials/issues-view.html', controller: "IssuesViewController"})

    $routeProvider.when('/project/:pid/tasks/:taskid',
            {templateUrl: 'partials/tasks-view.html', controller: "TasksViewController"})

    # $routeProvider.when('/project/:pid/questions',
    #         {templateUrl: 'partials/questions.html', controller: QuestionsController})

    # $routeProvider.when('/project/:pid/questions/:issueid',
    #         {templateUrl: 'partials/questions-view.html', controller: QuestionsViewController})

    # $routeProvider.when('/project/:pid/tasks',
    #         {templateUrl: 'partials/tasks.html', controller: TasksController})

    $routeProvider.when('/project/:pid/taskboard/:sid',
            {templateUrl: 'partials/taskboard.html', controller: "TaskboardController"})

    $routeProvider.when('/project/:pid/wiki/:slug',
            {templateUrl: 'partials/wiki.html', controller: "WikiController"})

    $routeProvider.when('/project/:pid/wiki/:slug/historical',
            {templateUrl: 'partials/wiki-historical.html', controller: "WikiHistoricalController"})

    $routeProvider.when('/project/:pid/search', {
        controller: "SearchController", templateUrl: "partials/search.html"})

    $routeProvider.when('/project/:pid/admin', {
        controller: "ProjectAdminController", templateUrl: "partials/project-admin.html"})

    $routeProvider.when('/admin', {
        controller: "SiteAdminController", templateUrl: "partials/site-admin.html"})

    $routeProvider.otherwise({redirectTo: '/login'})

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
        "roles": "/api/v1/roles"
        "projects": "/api/v1/projects"
        "memberships": "/api/v1/memberships"
        "milestones": "/api/v1/milestones"
        "userstories": "/api/v1/userstories"
        "bulk-create-us": "/api/v1/userstories/bulk_create"
        "bulk-update-us-order": "/api/v1/userstories/bulk_update_order"
        "userstories-historical": "/api/v1/userstories/%s/historical"
        "userstories-restore": "/api/v1/userstories/%s/restore"
        "userstories/attachments": "/api/v1/userstory-attachments"
        "tasks": "/api/v1/tasks"
        "tasks-historical": "/api/v1/tasks/%s/historical"
        "tasks-restore": "/api/v1/tasks/%s/restore"
        "tasks/attachments": "/api/v1/task-attachments"
        "issues": "/api/v1/issues"
        "issues-historical": "/api/v1/issues/%s/historical"
        "issues-restore": "/api/v1/issues/%s/restore"
        "issues/attachments": "/api/v1/issue-attachments"
        "wiki": "/api/v1/wiki"
        "wiki-historical": "/api/v1/wiki/%s/historical"
        "wiki-restore": "/api/v1/wiki/%s/restore"
        "wiki/attachments": "/api/v1/wiki-attachments"
        "choices/userstory-statuses": "/api/v1/userstory-statuses"
        "choices/points": "/api/v1/points"
        "choices/task-statuses": "/api/v1/task-statuses"
        "choices/issue-statuses": "/api/v1/issue-statuses"
        "choices/issue-types": "/api/v1/issue-types"
        "choices/priorities": "/api/v1/priorities"
        "choices/severities": "/api/v1/severities"
        "search": "/api/v1/search"
        "sites": "/api/v1/sites"
        "site-members": "/api/v1/site-members"
        "site-projects": "/api/v1/site-projects"
        "users": "/api/v1/users"
        "users-password-recovery": "/api/v1/users/password_recovery"
        "users-change-password-from-recovery": "/api/v1/users/change_password_from_recovery"
        "users-change-password": "/api/v1/users/change_password"
    }

    $gmUrlsProvider.setUrls("api", apiUrls)


modules = [
    "ngRoute",
    "ngAnimate",
    "ngSanitize",

    "greenmine.controllers.common",
    "greenmine.controllers.auth",
    "greenmine.controllers.backlog",
    "greenmine.controllers.user-story",
    "greenmine.controllers.search",
    "greenmine.controllers.taskboard",
    "greenmine.controllers.issues",
    "greenmine.controllers.project",
    "greenmine.controllers.tasks",
    "greenmine.controllers.wiki",
    "greenmine.controllers.site",
    "greenmine.filters",
    "greenmine.services.common",
    "greenmine.services.model",
    "greenmine.services.resource",
    "greenmine.directives.generic",
    "greenmine.directives.common",
    "greenmine.directives.graphs",
    "greenmine.directives.tasks",
    "greenmine.directives.issues",
    "greenmine.directives.history",
    "greenmine.directives.wiki",
    "greenmine.directives.backlog",

    "coffeeColorPicker",

    # Plugins modules.
    "gmUrls",
    "gmFlash",
    "gmModal",
    "gmStorage",
    "gmConfirm",
    "gmOverlay",
    "i18next",
]


init = ($rootScope, $location, $gmStorage, $gmAuth, $gmUrls, $i18next, config, $data, $log) ->
    if not config.debug
        $log.debug = ->

    $rootScope.pageTitle = ""
    $rootScope.auth = $gmAuth.getUser()
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

    $rootScope.constants.users = {}

    # Configure on init a default host and scheme for api urls.
    $gmUrls.setHost("api", config.host, config.scheme)

    $data.loadSiteInfo($rootScope).then (sitedata) ->
        $log.debug "Site data:", sitedata

    $rootScope.baseUrls =
        projects: "/"
        backlog: "/project/%s/backlog"
        taskboard: "/project/%s/taskboard/%s"
        userstory: "/project/%s/user-story/%s"
        issue: "/project/%s/issues/%s"
        issues: "/project/%s/issues"
        task: "/project/%s/tasks/%s"
        tasks: "/project/%s/tasks/%s"
        wiki: "/project/%s/wiki/%s"
        wikiHistorical: "/project/%s/wiki/%s/historical"
        search: "/project/%s/search"
        admin: "/project/%s/admin"

    conditionalUrl = (url, raw) ->
        return url if raw
        return "/##{url}"

    # TODO: refactor this.
    $rootScope.urls =
        projectsUrl: ->
            return '/#/'

        backlogUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.backlog, [projectId])
            return conditionalUrl(url, raw)

        taskboardUrl: (projectId, sprintId, raw) ->
            url = gm.format($rootScope.baseUrls.taskboard, [projectId, sprintId])
            return conditionalUrl(url, raw)

        userStoryUrl: (projectId, userStoryId, raw) ->
            url = gm.format($rootScope.baseUrls.userstory, [projectId, userStoryId])
            return conditionalUrl(url, raw)

        adminUrl: (projectId,  raw) ->
            url = gm.format($rootScope.baseUrls.admin, [projectId])
            return conditionalUrl(url, raw)

        issuesUrl: (projectId, issueId, raw) ->
            url = null

            if issueId != undefined
                url = gm.format($rootScope.baseUrls.issue, [projectId, issueId])
            else
                url = gm.format($rootScope.baseUrls.issues, [projectId])

            return conditionalUrl(url, raw)

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

        searchUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.search, [projectId])
            return conditionalUrl(url, raw)

    $rootScope.momentFormat = (input, format) ->
        return moment(input).format(format)

    $rootScope.logout = () ->
        $gmStorage.clear()
        $location.url("/login")

    $i18next.initialize(false, config.defaultLanguage)
    $rootScope.$on "i18n:change", (event, lang) ->
        if lang
            new_lang = lang
        else if $rootScope.auth.default_language
            new_lang = $rootScope.auth.default_language
        else if $rootScope.site.data.default_language
            new_lang = $rootScope.site.data.default_language
        else
            new_lang = config.defaultLanguage

        $i18next.setLang(new_lang)
        moment.lang(new_lang)

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

angular.module('greenmine', modules)
       .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', '$gmUrlsProvider', configCallback])
       .run(['$rootScope', '$location', '$gmStorage', '$gmAuth', '$gmUrls', '$i18next', 'config', '$data', '$log', init])

angular.module('greenmine.config', []).value('config', {
    host: "localhost:8000"
    scheme: "http"
    defaultLanguage: "en"
    notificationLevelOptions: {
        "all_owned_projects": "All events on my projects"
        "only_watching": "Only events for objects i watch"
        "only_assigned": "Only events for objects assigned to me"
        "only_owner": "Only events for objects owned by me"
        "no_events": "No events"
    }
})
