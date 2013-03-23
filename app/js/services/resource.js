"use strict";

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
    $provide.factory('resource', ['$q', '$http', 'storage', 'greenmine.config', function($q, $http, storage, config) {
        var userStoriesByProject = function(projectId) {
            var defered = $q.defer();

            $http.get("tmpresources/dashboard-userstories.json").
                success(function(data, status) {
                    defered.resolve(data);
                }).
                error(function(data, status) {
                    defered.reject(data);
                });

            return defered.promise;
        };

        var service = {};
        service.userStoriesByProject = userStoriesByProject;

        return service;
    }]);
});
