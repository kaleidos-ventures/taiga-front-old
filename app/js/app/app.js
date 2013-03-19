'use strict';

(function() {
    var configCallback = function($routeProvider, $locationProvider, $httpProvider, $provide, $compileProvider) {
        $routeProvider.when('/login', {templateUrl: 'partials/login.html', controller: LoginController});
        $routeProvider.when('/register', {templateUrl: 'partials/register.html', controller: RegisterController});
        $routeProvider.when('/recovery', {templateUrl: 'partials/recovery.html', controller: RecoveryController});
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
        //"greenmine.filters.common",
        "greenmine.services.common",
        //"greenmine.services.storage",
        "greenmine.directives.common"
    ];

    if (this.greenmine === undefined) this.greenmine = {};

    var init = function($rootScope) {
        // Entry point
    };

    angular.module('greenmine', modules)
        .config(['$routeProvider', '$locationProvider', '$httpProvider', '$provide', '$compileProvider', configCallback])
        .run(['$rootScope', init]);

}).call(this);
