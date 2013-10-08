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

configCallback = ($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider) ->
    $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: "LoginController"})
    $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: "RegisterController"})
    $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: "RecoveryController"})
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


modules = [
    "ngRoute",
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
    "greenmine.filters.common",
    "greenmine.services.common",
    "greenmine.services.model",
    "greenmine.services.resource",
    "greenmine.directives.generic",
    "greenmine.directives.common",
    "greenmine.directives.taskboard",
    "greenmine.directives.issues",
    "greenmine.directives.wiki",

    # Plugins modules.
    "gmFlash",
    "gmModal",
    "gmStorage",
    "gmConfirm",
    "gmOverlay",
]


init = ($rootScope, $location, $gmStorage) ->
    $rootScope.auth = $gmStorage.get('userInfo')
    $rootScope.constants = {}
    $rootScope.constants.points = {}
    $rootScope.constants.severity = {}
    $rootScope.constants.priority = {}
    $rootScope.constants.status = {}
    $rootScope.constants.type = {}
    $rootScope.constants.users = {}

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
       .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', configCallback])
       .run(['$rootScope', '$location', '$gmStorage', init])

angular.module('greenmine.config', []).value('greenmine.config', {host: "localhost:8000", scheme: "http"})
