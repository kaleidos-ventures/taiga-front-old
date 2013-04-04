"use strict";

angular.module('greenmine.services.storage', ['greenmine.config'], function($provide) {
    $provide.factory('storage', ['$rootScope', function($rootScope) {
        var service = {};
        var helpers = {};

        service.get = function(key) {
            var serializedValue = sessionStorage.getItem(key)
            if (serializedValue === null)
                return serializedValue;

            return JSON.parse(serializedValue);
        };

        service.set = function(key, val) {
            if (_.isObject(key)) {
                _.each(key, function(val, key) {
                    service.set(key, val);
                });
            } else {
                sessionStorage.setItem(key, JSON.stringify(val));
            }
        };

        service.remove = function(key) {
            sessionStorage.removeItem(key);
        };

        service.clear = function() {
            sessionStorage.clear();
        };

        return service;
    }]);
});
