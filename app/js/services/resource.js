"use strict";

/* Model */

(function() {
    var saveDefaults = {
        patch: true,
    };

    this.Model = function(data, options) {
        this._attrs = data;
        this._modifiedAttrs = {};
        this._isModified = false;

        if (options !== undefined) {
            this.httpService = options.httpService;
            this.resolveUrl = options.resolveUrl;
            this.headers = options.headers;
            this.httpReady = true;
        }

        this.initialize();
    };

    var fn = this.Model.prototype;

    fn.initialize = function() {
        var self = this;

        _.each(self._attrs, function(value, name) {
            (function(name) {
                Object.defineProperty(self, name, {
                    get: function() {
                        if (self._modifiedAttrs[name] !== undefined) {
                            return self._modifiedAttrs[name];
                        } else {
                            return self._attrs[name];
                        }
                    },
                    set: function(value) {
                        this._modifiedAttrs[name] = value;
                        this._isModified = true;
                    },
                    enumerable : true,
                    configurable : true
                });
            })(name);
        });
    }


    fn.isModified = function() {
        return this._isModified;
    };

    fn.revert = function() {
        this._modifiedAttrs = {};
        this._isModified = false;
    };

    fn.save = function(options) {
        var self = this;
        var defered = Q.defer(), postObject, q;

        options = _.extend({}, saveDefaults, options || {});

        if (!this.isModified()) {
            defered.resolve(true);
        } else {
            if (options.patch) {
                postObject = _.extend({id: this.id}, this._modifiedAttrs);
            } else {
                postObject = _.extend(this._attrs, this._modifiedAttrs);
            }

            var params = {
                method: options.patch ? "PATCH" : "PUT",
                url: this.resolveUrl(this.id),
                headers: this.headers(),
                data: JSON.stringify(postObject)
            };

            q = this.httpService(params);
            q.success(function(data, status) {
                self._isModified = false;
                self._attrs = _.extend(self._attrs, self._modifiedAttrs);
                self._modifiedAttrs = {};
                defered.resolve(data, status);
            });
            q.error(function(data, status) {
                defered.reject(data, status);
            });
        }

        return defered.promise;
    };
}).call(this);

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
   $provide.factory("url", ['greenmine.config', function(config) {
        var urls = {
            "auth": "/api/auth/login/",
            "projects": "/api/scrum/projects/",
            "project": "/api/gm/project/%s/",
            "userstories": "/api/scrum/user_stories/",
            "userstory": "/api/scrum/user_stories/%s/",
            "milestones": "/api/scrum/milestones/",
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

    $provide.factory('resource', ['$http', 'storage', 'url', 'greenmine.config', function($http, storage, url, config) {
        var service = {};

        var headers = function() {
            return {"X-SESSION-TOKEN": storage.get('token')};
        };

        var toJson = function(data) {
            return JSON.stringify(data);
        };

        /* Login request */
        service.login = function(username, password) {
            var defered = Q.defer();

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
            var defered = Q.defer(), q, resolveUrl;

            resolveUrl = function(id) {
                return url("project", id);
            };

            q = $http({method:"GET", url: url('projects'), headers: headers()});
            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item, {
                        resolveUrl: resolveUrl,
                        headers: headers,
                        httpService: $http
                    });
                });

                defered.resolve(objects);
            });

            return defered.promise;
        };

        /* Get available task statuses for a project. */
        service.getTaskStatuses = function(projectId) {
            var defered = Q.defer(), q;

            q = $http({method:"GET", url: url('choices/task-status'),
                       params: {project: projectId}, headers: headers()});

            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item);
                });

                defered.resolve(objects);
            });

            return defered.promise;
        };

        /* Get a user stories list by projectId and sprintId. */
        service.getMilestoneUserStories = function(projectId, sprintId) {
            var defered = Q.defer(), q, resolveUrl;

            resolveUrl = function(id) {
                return url("userstory", id);
            };

            q = $http.get("tmpresources/dashboard-userstories.json");
            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item, {
                        resolveUrl: resolveUrl,
                        headers: headers,
                        httpService: $http
                    });
                });

                defered.resolve(objects);
            });

            return defered.promise;
        };

        /* Get a milestone lines for a project. */
        service.getMilestones = function(projectId) {
            var defered = Q.defer(), q, resolveUrl

            resolveUrl = function(id) {
                return url("milestone", id);
            };

            q = $http({method:"GET", url: url('milestones'),
                   params: {project: projectId}, headers: headers()});

            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item, {
                        resolveUrl: resolveUrl,
                        headers: headers,
                        httpService: $http
                    });
                });

                defered.resolve(objects);
            });

            return defered.promise;

        };

        /* Get unassigned user stories list for
         * a project. */
        service.getUnassignedUserStories = function(projectId) {
            var defered = Q.defer(), q, resolveUrl

            q = $http({method: "GET", url: url("userstories"), headers: headers(),
                           params:{"project":projectId, "milestone": "null"}})

            resolveUrl = function(id) {
                return url("userstory", id);
            };

            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item, {
                        resolveUrl: resolveUrl,
                        headers: headers,
                        httpService: $http
                    });
                });

                defered.resolve(objects);
            });

            return defered.promise;
        };

        /* Get project Issues list */
        service.getIssues = function(projectId) {
            var defered = Q.defer(), q, resolveUrl;

            resolveUrl = function(id) {
                return url("issue", id);
            };

            q = $http.get("tmpresources/issues.json");
            q.success(function(data, status) {
                var objects = _.map(data, function(item) {
                    return new Model(item, {
                        resolveUrl: resolveUrl,
                        headers: headers,
                        httpService: $http
                    });
                });
            });

            return defered.promise;
        };

        /* Get a users with role developer for
         * one concret project. */
        service.projectDevelopers = function(projectId) {
            var defered = Q.defer();

            $http.get("tmpresources/project-developers.json").
                success(function(data, status) {
                    defered.resolve(data);
                });

            return defered.promise;
        }

        return service;
    }]);
});
