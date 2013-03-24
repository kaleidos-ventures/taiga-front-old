"use strict";

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
    $provide.factory('resource', ['$q', '$http', 'storage', 'greenmine.config', function($q, $http, storage, config) {
        var service = {};

        /* Get a user stories list by projectId and sprintId. */
        service.milestoneUserStories = function(projectId, sprintId) {
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

        /* Get unassigned user stories list for
         * a project. */
        service.getUnassignedUserStories = function(projectId) {
            var defered = $q.defer();
            $http.get("tmpresources/backlog-unassigned-us.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        };

        /* Get project milestones list */
        service.getMilestones = function(projectId) {
            var defered = $q.defer();
            $http.get("tmpresources/backlog-milestones.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        };

        /* Get project Issues list */
        service.getIssues = function(projectId) {
            var defered = $q.defer();
            $http.get("tmpresources/issues.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        };

        /* Get a users with role developer for
         * one concret project. */
        service.projectDevelopers = function(projectId) {
            var defered = $q.defer();

            $http.get("tmpresources/project-developers.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        }

        return service;
    }]);
});
