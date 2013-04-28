angular.module('greenmine.services.common', ['greenmine.config'], ($provide) ->
    $provide.factory('notify', ['$rootScope', ($rootScope) ->
        return (type, messages, timeout) ->
            $rootScope.$broadcast('$notify', type, messages, timeout)
    ])
).value('version', '0.1')
