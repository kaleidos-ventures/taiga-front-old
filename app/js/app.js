'use strict';

(function() {
    var configCallback = function($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider) {
        $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: LoginController});
        $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: RegisterController});
        $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: RecoveryController});
        $routeProvider.when('/projects', {templateUrl: 'partials/project-list.html', controller: ProjectListController});

        $routeProvider.when('/project/:pid/backlog',
                {templateUrl: 'partials/backlog.html', controller: BacklogController});

        $routeProvider.when('/project/:pid/dashboard',
                {templateUrl: 'partials/dashboard.html', controller: DashboardController});

        $routeProvider.otherwise({redirectTo: '/login'});
        $locationProvider.hashPrefix('!');

        $httpProvider.defaults.headers.delete = {"Content-Type": "application/json"};
        $httpProvider.defaults.headers.patch = {"Content-Type": "application/json"};

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
        "greenmine.directives.common",
        "greenmine.directives.jqueryui",
        "greenmine.directives.dashboard"
    ];

    if (this.greenmine === undefined) this.greenmine = {};

    var init = function($rootScope, storage) {
        // Initial hack
        storage.set("userInfo", {"id": "12345", "username": "niwibe", "fullname": "Andrey Antukh"});

        $rootScope.auth = storage.get('userInfo');
    };

    angular.module('greenmine', modules)
        .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', configCallback])
        .run(['$rootScope', 'storage', init]);

}).call(this);
