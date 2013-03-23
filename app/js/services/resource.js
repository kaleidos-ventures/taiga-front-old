"use strict";

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
    $provide.factory('resource', ['$q', '$http', 'storage', 'greenmine.config', function($q, $http, storage, config) {
        /*
         * Get a user stories list by projectId and sprintId.
        */

        var userStoriesByProject = function(projectId, sprintId) {
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

        /*
         * Obtain a users with role developer for
         * one concret project.
        */

        var projectDevelopers = function(projectId) {
            var defered = $q.defer();

            $http.get("tmpresources/project-developers.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        }

        var service = {};
        service.userStoriesByProject = userStoriesByProject;
        service.projectDevelopers = projectDevelopers;

        return service;
    }]);
});
