"use strict";

/* Model */

angular.module('greenmine.services.resource', ['greenmine.config'], function($provide) {
   $provide.factory("url", ['greenmine.config', function(config) {
        var urls = {
            "auth": "/api/auth/login/",
            "projects": "/api/scrum/projects/",
            "userstories": "/api/scrum/user_stories/",
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
        var service = {}
            , headers
            , toJson
            , interpolate;

        /* Resource Utils */

        headers = function() {
            return {"X-SESSION-TOKEN": storage.get('token')};
        };

        toJson = function(data) {
            return JSON.stringify(data);
        };

        interpolate = function(fmt, obj, named) {
            if (named) {
                return fmt.replace(/%\(\w+\)s/g, function(match){return String(obj[match.slice(2,-2)])});
            } else {
                return fmt.replace(/%s/g, function(match){return String(obj.shift())});
            }
        }

        /* Resource Model */

        var Model = function(data, url, options) {
            this._attrs = data;
            this._modifiedAttrs = {};
            this._isModified = false;
            this._url = url;

            this.initialize();
        };

        Model.prototype.initialize = function() {
            var self = this;

            var getter = function(name) {
                return function() {
                    if (name.substr(0,2) === "__") {
                        return self[name];
                    }

                    if (self._modifiedAttrs[name] !== undefined) {
                        return self._modifiedAttrs[name];
                    } else {
                        return self._attrs[name];
                    }
                };
            };

            var setter = function(name) {
                return function(value) {
                    // Ignore all attrs stats with "__"
                    if (name.substr(0,2) === "__") {
                        self[name] = value
                    } else {
                        if (self._attrs[name] !== value) {
                            self._modifiedAttrs[name] = value;
                            self._isModified = true;
                        }
                    }
                };
            };

            _.each(self._attrs, function(value, name) {
                var propertyOptions = {
                    get: getter(name),
                    enumerable : true,
                    configurable : true
                };

                /* Id field does not have setter */
                if (name !== "id") {
                    propertyOptions.set = setter(name);
                }

                Object.defineProperty(self, name, propertyOptions);
            });
        };

        Model.prototype.isModified = function() {
            return this._isModified;
        };

        Model.prototype.revert = function() {
            this._modifiedAttrs = {};
            this._isModified = false;
        };

        Model.prototype.delete = function() {
            var params, defered = Q.defer();

            params = {
                method: "DELETE",
                url: this._url,
                headers: headers()
            };

            $http(params).success(function(data, status) {
                defered.resolve(data, status);
            }).error(function(data, status) {
                defered.reject(data, status);
            });

            return defered.promise;
        };

        Model.prototype.save = function() {
            var self = this, defered = Q.defer(), postObject;

            if (!this.isModified()) {
                defered.resolve(true);
            } else {
                postObject = _.extend({}, this._modifiedAttrs);

                var params = {
                    method: "PATCH",
                    url: this._url,
                    headers: headers(),
                    data: toJson(postObject)
                };


                $http(params).success(function(data, status) {
                    self._isModified = false;
                    self._attrs = _.extend(self._attrs, self._modifiedAttrs);
                    self._modifiedAttrs = {};
                    defered.resolve(data, status);
                }).error(function(data, status) {
                    defered.reject(data, status);
                });
            }

            return defered.promise;
        };

        /* Resource Action Helpers */

        var itemUrlTemplate = "%(url)s(id)s/";

        var queryMany = function(url, params) {
            var params = {"method":"GET", "headers": headers(), "url": url, params: params || {}};
            var defered = Q.defer();

            $http(params).success(function(data, status) {
                var models = _.map(data, function(item) {
                    var modelurl = interpolate(itemUrlTemplate, {"url": url, "id": item.id}, true);
                    return new Model(item, modelurl);
                });
                defered.resolve(models);
            }).error(function(data, status) {
                defered.reject(data, status);
            });

            return defered.promise;
        };

        var queryOne = function(url, params) {
            var paramsDefault = {"method":"GET", "headers": headers(), "url": url};
            var defered = Q.defer();

            params = _.extend({}, paramsDefault, params || {});

            $http(params).success(function(data, status) {
                var model = new Model(item, {url: url});
                defered.resolve(model);
            }).error(function(data, status) {
                defered.reject(data, status);
            });

            return defered.promise;
        };


        /* Resource Methods */

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

        /* Get a project list */
        service.getProjects = function() {
            return queryMany(url('projects'));
        };

        /* Get available task statuses for a project. */
        service.getTaskStatuses = function(projectId) {
            return queryMany(url('choices/task-status'), {project: projectId});
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
            // First step: obtain data
            var _getMilestones = function() {
                var defered = Q.defer();
                var params = {"method":"GET", "headers": headers(), "url": url("milestones")};

                $http(params).success(function(data, status) {
                    defered.resolve(data);
                }).error(function(data, status) {
                    defered.reject(data, status);
                })

                return defered.promise;
            }

            // Second step: make user story models
            var _makeUserStoryModels = function(objects) {
                var baseUrl = url("userstories");

                _.each(objects, function(milestone) {
                    var user_stories = _.map(milestone.user_stories, function(item) {
                        var modelurl = interpolate(itemUrlTemplate, {"url": baseUrl, "id": item.id}, true);
                        return new Model(item, modelurl);
                    });

                    milestone.user_stories = user_stories;
                });

                return objects;
            };

            // Third step: make milestone models
            var _makeModels = function(objects) {
                var baseUrl = url("milestones");

                return _.map(objects, function(item) {
                    var modelurl = interpolate(itemUrlTemplate, {"url": baseUrl, "id": item.id}, true);
                    return new Model(item, modelurl);
                });
            };

            return _getMilestones()
                        .then(_makeUserStoryModels)
                        .then(_makeModels);
        };

        /* Get unassigned user stories list for a project. */
        service.getUnassignedUserStories = function(projectId) {
            return queryMany(url("userstories"),
                {"project":projectId, "milestone": "null"});
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
