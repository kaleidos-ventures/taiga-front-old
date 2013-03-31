'use strict';

(function() {
    var configCallback = function($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider) {
        $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: LoginController});
        $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: RegisterController});
        $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: RecoveryController});
        $routeProvider.when('/', {templateUrl: 'partials/project-list.html', controller: ProjectListController});

        $routeProvider.when('/project/:pid/backlog',
                {templateUrl: 'partials/backlog.html', controller: BacklogController});

        $routeProvider.when('/project/:pid/issues',
                {templateUrl: 'partials/issues.html', controller: IssuesController});

        $routeProvider.when('/project/:pid/issues/:issueid',
                {templateUrl: 'partials/issues-view.html', controller: IssuesViewController});

        //$routeProvider.when('/project/:pid/tasks',
        //        {templateUrl: 'partials/tasks.html', controller: TasksController});

        $routeProvider.when('/project/:pid/dashboard/:sid',
                {templateUrl: 'partials/dashboard.html', controller: DashboardController});

        $routeProvider.when('/project/:pid/wiki/:slug',
                {templateUrl: 'partials/wiki.html', controller: WikiController});

        $routeProvider.otherwise({redirectTo: '/login'});
        $locationProvider.hashPrefix('!');

        var defaultHeaders = {
            "Content-Type": "application/json",
            //"Accept-Encoding": "application/json"
        };

        $httpProvider.defaults.headers.delete = defaultHeaders;
        $httpProvider.defaults.headers.patch = defaultHeaders;
        $httpProvider.defaults.headers.post = defaultHeaders;
        $httpProvider.defaults.headers.put = defaultHeaders;

        $provide.factory("authHttpIntercept", ["$q", "$location", function($q, $location) {
            return function(promise) {
                return promise.then(null, function(response) {
                    if (response.status === 401) {
                        $location.url("/login");
                    }
                    return $q.reject(response);
                });
            };
        }]);

        $compileProvider.urlSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|blob):/);
        $httpProvider.responseInterceptors.push('authHttpIntercept');
    };

    var modules = [
        "greenmine.filters.common",
        "greenmine.services.common",
        "greenmine.services.resource",
        "greenmine.services.storage",
        "greenmine.directives.generic",
        "greenmine.directives.common",
        "greenmine.directives.backlog",
        "greenmine.directives.dashboard",
        "greenmine.directives.issues",
        "greenmine.directives.wiki"
    ];

    if (this.greenmine === undefined) this.greenmine = {};

    var init = function($rootScope, storage) {
        // Initial hack
        storage.set("userInfo", {"id": "12345", "username": "niwibe", "fullname": "Andrey Antukh"});

        $rootScope.auth = storage.get('userInfo');
        $rootScope.constants = {};
        $rootScope.constants.points = {};
        $rootScope.constants.severity = {};
        $rootScope.constants.priority = {};
        $rootScope.constants.status = {};
        $rootScope.constants.type = {};

        /* Global helpers */

        $rootScope.resolvePoints = function(id) {
            var point = $rootScope.constants.points[id];
            return point ? point.name : undefined;
        };

        $rootScope.resolveStatus = function(id) {
            var status = $rootScope.constants.status[id];
            return status ? status.name : undefined;
        };

        $rootScope.resolvePriority = function(id) {
            var priority = $rootScope.constants.priority[id];
            return priority ? priority.name : undefined;
        };

        $rootScope.resolveSeverity = function(id) {
            var severity = $rootScope.constants.severity[id];
            return severity ? severity.name : undefined;
        };

        $rootScope.resolveType = function(id) {
            var type = $rootScope.constants.type[id];
            return type ? type.name : undefined;
        };

        /* Navigation url resolvers */

        $rootScope.urls = {
            backlogUrl: function(projectId) {
                return _.str.sprintf("/#!/project/%s/backlog", projectId);
            },

            dashboardUrl: function(projectId, sprintId) {
                return _.str.sprintf("/#!/project/%s/dashboard/%s", projectId, sprintId);
            },

            issuesUrl: function(projectId, issueId) {
                if (issueId === undefined) {
                    return _.str.sprintf("/#!/project/%s/issues", projectId);
                } else {
                    return _.str.sprintf("/#!/project/%s/issues/%s", projectId, issueId);
                }
            },

            wikiUrl: function(projectId, pageName) {
                return _.str.sprintf("/#!/project/%s/wiki/%s", projectId, _.str.slugify(pageName));
            }
        };
    };

    angular.module('greenmine', modules)
        .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', configCallback])
        .run(['$rootScope', 'storage', init]);

}).call(this);
