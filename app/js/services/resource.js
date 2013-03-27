"use strict";

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
   $provide.factory("url", ['greenmine.config', function(config) {
        var urls = {
            "auth": "/api/auth/login/",
            "projects": "/api/scrum/projects/",
            "project": "/api/gm/project/%s",
            "choices/task-status": "/api/scrum/task_status/",
        }, host = config.host, scheme=config.scheme;

        return function() {
            var args = _.toArray(arguments);
            var name = args.slice(0, 1);
            var params = [urls[name]];

            _.each(args.slice(1), function(item) {
                params.push(item);
            });

            var url = _.str.sprintf.apply(null, params);
            return _.str.sprintf("%s://%s%s", scheme, host, url);
        };
    }]);

    $provide.factory('resource', ['$q', '$http', 'storage', 'url', 'greenmine.config', function($q, $http, storage, url, config) {
        var service = {};

        var headers = function() {
            return {"X-SESSION-TOKEN": storage.get('token')};
        };

        var toJson = function(data) {
            return JSON.stringify(data);
        };

        /* Login request */
        service.login = function(username, password) {
            var defered = $q.defer();

            var onSuccess = function(data, status) {
                storage.set("token", data["token"]);
                defered.resolve(data);
            };

            var onError = function(data, status) {
                defered.reject(data);
            };

            var postData = {"username": username, "password":password};

            $http({method:'POST', url: url('auth'), data: toJson(postData)})
                .success(onSuccess).error(onError);

            return defered.promise;
        };

        service.getProjects = function() {
            var defered = Q.defer();

            $http({method:"GET", url: url('projects')}).
                success(function(data) { defered.resolve(data); });

            return defered.promise;
        };

        /* Get available task statuses for a project. */
        service.getTaskStatuses = function(projectId) {
            var defered = Q.defer();

            $http({method:"GET", url: url('choices/task-status'),
                params: {project: projectId}, headers: headers()}).
                success(function(data) { defered.resolve(data); });

            return defered.promise;
        };

        /* Get a user stories list by projectId and sprintId. */
        service.getMilestoneUserStories = function(projectId, sprintId) {
            var defered = Q.defer();

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
