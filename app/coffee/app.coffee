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
    $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: "LoginController"})
    $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: "RegisterController"})
    $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: "RecoveryController"})
    $routeProvider.when('/change-password', {templateUrl: 'partials/change-password.html', controller: "ChangePasswordController"})
    $routeProvider.when('/change-password/:token', {templateUrl: 'partials/change-password.html', controller: "ChangePasswordController"})
    $routeProvider.when('/profile', {templateUrl: 'partials/profile.html', controller: "ProfileController"})

    $routeProvider.when('/', {templateUrl: 'partials/project-list.html', controller: "ProjectListController"})

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

    $routeProvider.when('/project/:pid/search', {
        controller: "SearchController", templateUrl: "partials/search.html"})

    $routeProvider.when('/project/:pid/admin', {
        controller: "ProjectAdminController", templateUrl: "partials/project-admin.html"})

    #$routeProvider.otherwise({redirectTo: '/login'})

    defaultHeaders =
        "Content-Type": "application/json",
        "Accept-Language": "en"

    $httpProvider.defaults.headers.delete = defaultHeaders
    $httpProvider.defaults.headers.patch = defaultHeaders
    $httpProvider.defaults.headers.post = defaultHeaders
    $httpProvider.defaults.headers.put = defaultHeaders

    authHttpIntercept = ($q, $location) ->
        return (promise) ->
            return promise.then null, (response) ->
                if response.status == 401 or response.status == 0
                    $location.url("/login")
                return $q.reject(response)

    $provide.factory("authHttpIntercept", ["$q", "$location", authHttpIntercept])
    $httpProvider.responseInterceptors.push('authHttpIntercept')

    apiUrls = {
        "auth": "/api/v1/auth"
        "roles": "/api/v1/roles"
        "projects": "/api/v1/projects"
        "memberships": "/api/v1/memberships"
        "milestones": "/api/v1/milestones"
        "userstories": "/api/v1/userstories"
        "userstories/attachments": "/api/v1/userstory-attachments"
        "tasks": "/api/v1/tasks"
        "tasks/attachments": "/api/v1/task-attachments"
        "issues": "/api/v1/issues"
        "issues/attachments": "/api/v1/issue-attachments"
        "wiki": "/api/v1/wiki"
        "wiki/attachments": "/api/v1/wiki-attachments"
        "choices/task-status": "/api/v1/task-statuses"
        "choices/issue-status": "/api/v1/issue-statuses"
        "choices/issue-types": "/api/v1/issue-types"
        "choices/us-status": "/api/v1/userstory-statuses"
        "choices/points": "/api/v1/points"
        "choices/priorities": "/api/v1/priorities"
        "choices/severities": "/api/v1/severities"
        "search": "/api/v1/search"

        "users": "/api/v1/users"
        "users-password-recovery": "/api/v1/users/password_recovery"
        "users-change-password-from-recovery": "/api/v1/users/change_password_from_recovery"
        "users-change-password": "/api/v1/users/change_password"
    }

    $gmUrlsProvider.setUrls("api", apiUrls)


modules = [
    "ngRoute",
    "ngSanitize",
    "ngAnimate",
    "coffeeColorPicker",

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
    "greenmine.filters",
    "greenmine.services.common",
    "greenmine.services.model",
    "greenmine.services.resource",
    "greenmine.directives.generic",
    "greenmine.directives.common",
    "greenmine.directives.taskboard",
    "greenmine.directives.tasks",
    "greenmine.directives.issues",
    "greenmine.directives.wiki",
    "greenmine.directives.backlog",

    # Plugins modules.
    "gmUrls",
    "gmFlash",
    "gmModal",
    "gmStorage",
    "gmConfirm",
    "gmOverlay",
]


init = ($rootScope, $location, $gmStorage, $gmAuth, $gmUrls, config) ->
    # Constants
    $rootScope.auth = $gmAuth.getUser()
    $rootScope.constants = {}

    $rootScope.constants.usStatuses = {}
    $rootScope.constants.usStatusesList = []
    $rootScope.constants.points = {}
    $rootScope.constants.pointsList = []
    $rootScope.constants.pointsByOrder = {}

    $rootScope.constants.taskStatuses = {}
    $rootScope.constants.taskStatusesList = []

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

        searchUrl: (projectId, raw) ->
            url = gm.format($rootScope.baseUrls.search, [projectId])
            return conditionalUrl(url, raw)

    $rootScope.logout = () ->
        $gmStorage.clear()
        $location.url("/login")

angular.module('greenmine', modules)
       .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', '$gmUrlsProvider', configCallback])
       .run(['$rootScope', '$location', '$gmStorage', '$gmAuth', '$gmUrls', 'config', init])

angular.module('greenmine.config', []).value('config', {host: "localhost:8000", scheme: "http"})
