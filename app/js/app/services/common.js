'use strict';

/* Services */

angular.module('greenmine.services.common', ['greenmine.config'], function($provide) {
    $provide.factory('notify', ['$rootScope', function($rootScope) {
        return function(type, messages, timeout) {
            $rootScope.$broadcast('$notify', type, messages, timeout);
        };
    }]);

    $provide.factory("url", ['greenmine.config', function(config) {
        var urls = {
            "auth": "/api/v1/login",
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
}).value('version', '0.1');
