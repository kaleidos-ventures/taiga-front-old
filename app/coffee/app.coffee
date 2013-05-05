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

@greenmine = {} if not @greenmine?

configCallback = ($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider) ->
    $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: LoginController})
    $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: RegisterController})
    $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: RecoveryController})
    $routeProvider.when('/', {templateUrl: 'partials/project-list.html', controller: ProjectListController})

    $routeProvider.when('/project/:pid/backlog',
            {templateUrl: 'partials/backlog.html', controller: BacklogController})

    $routeProvider.when('/project/:pid/issues',
            {templateUrl: 'partials/issues.html', controller: IssuesController})

    $routeProvider.when('/project/:pid/issues/:issueid',
            {templateUrl: 'partials/issues-view.html', controller: IssuesViewController})

    # $routeProvider.when('/project/:pid/questions',
    #         {templateUrl: 'partials/questions.html', controller: QuestionsController})

    # $routeProvider.when('/project/:pid/questions/:issueid',
    #         {templateUrl: 'partials/questions-view.html', controller: QuestionsViewController})

    # $routeProvider.when('/project/:pid/tasks',
    #         {templateUrl: 'partials/tasks.html', controller: TasksController})

    $routeProvider.when('/project/:pid/dashboard/:sid',
            {templateUrl: 'partials/dashboard.html', controller: DashboardController})

    $routeProvider.when('/project/:pid/wiki/:slug',
            {templateUrl: 'partials/wiki.html', controller: WikiController})

    $routeProvider.otherwise({redirectTo: '/login'})
    $locationProvider.hashPrefix('!')

    defaultHeaders =
        "Content-Type": "application/json",

    $httpProvider.defaults.headers.delete = defaultHeaders
    $httpProvider.defaults.headers.patch = defaultHeaders
    $httpProvider.defaults.headers.post = defaultHeaders
    $httpProvider.defaults.headers.put = defaultHeaders

    $provide.factory("authHttpIntercept", ["$q", "$location", ($q, $location) ->
        return (promise) ->
            return promise.then(null, (response) ->
                if response.status == 401
                    $location.url("/login")
                return $q.reject(response)
            )
        ])

    $compileProvider.urlSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|blob):/)
    $httpProvider.responseInterceptors.push('authHttpIntercept')


modules = [
    "greenmine.filters.common",
    "greenmine.services.common",
    "greenmine.services.model",
    "greenmine.services.resource",
    "greenmine.services.storage",
    "greenmine.directives.generic",
    "greenmine.directives.common",
    "greenmine.directives.dashboard",
    "greenmine.directives.issues",
    "greenmine.directives.wiki"
]


init = ($rootScope, $location, storage) ->
    storage.set("userInfo", {"id": "12345", "username": "niwibe", "fullname": "Andrey Antukh"})

    $rootScope.auth = storage.get('userInfo')
    $rootScope.constants = {}
    $rootScope.constants.points = {}
    $rootScope.constants.severity = {}
    $rootScope.constants.priority = {}
    $rootScope.constants.status = {}
    $rootScope.constants.type = {}
    $rootScope.constants.users = {}

    $rootScope.resolvePoints = (id) ->
        point = $rootScope.constants.points[id]
        return if point? then point.name else undefined

    $rootScope.resolveStatus = (id) ->
        status = $rootScope.constants.status[id]
        return if status? then status.name else undefined

    $rootScope.resolvePriority = (id) ->
        priority = $rootScope.constants.priority[id]
        return if priority? then priority.name else undefined

    $rootScope.resolveSeverity = (id) ->
        severity = $rootScope.constants.severity[id]
        return if severity? then severity.name else undefined

    $rootScope.resolveType = (id) ->
        type = $rootScope.constants.type[id]
        return if type? then type.name else undefined

    $rootScope.resolveUser = (id) ->
        user = $rootScope.constants.users[id]
        return if user? then user.username else "Unassigned"

    $rootScope.urls =
        backlogUrl: (projectId) ->
            return _.str.sprintf("/#!/project/%s/backlog", projectId)

        dashboardUrl: (projectId, sprintId) ->
            return _.str.sprintf("/#!/project/%s/dashboard/%s", projectId, sprintId)

        issuesUrl: (projectId, issueId) ->
            if issueId != undefined
                return _.str.sprintf("/#!/project/%s/issues/%s", projectId, issueId)
            else
                return _.str.sprintf("/#!/project/%s/issues", projectId)

        questionsUrl: (projectId, issueId) ->
            if issueId is undefined
                return _.str.sprintf("/#!/project/%s/questions/%s", projectId, issueId)
            else
                return _.str.sprintf("/#!/project/%s/questions", projectId)

        wikiUrl: (projectId, pageName) ->
            return _.str.sprintf("/#!/project/%s/wiki/%s", projectId, _.str.slugify(pageName))

    $rootScope.logout = () ->
        storage.clear()
        $location.url("/login")

angular
    .module('greenmine', modules)
    .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', configCallback])
    .run(['$rootScope', '$location', 'storage', init])
