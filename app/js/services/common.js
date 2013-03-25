'use strict';

/* Services */

angular.module('greenmine.services.common', ['greenmine.config'], function($provide) {
    $provide.factory('notify', ['$rootScope', function($rootScope) {
        return function(type, messages, timeout) {
            $rootScope.$broadcast('$notify', type, messages, timeout);
        };
    }]);
}).value('version', '0.1');
