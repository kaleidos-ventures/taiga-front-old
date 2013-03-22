angular.module('greenmine.filters.common', []).
    filter('onlyVisible', [function() {
        return function(input) {
            return _.filter(input, function(item) {
                return (item.hidden !== true);
            });
        };
    }]);
