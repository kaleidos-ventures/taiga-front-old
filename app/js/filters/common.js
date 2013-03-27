angular.module('greenmine.filters.common', []).
    filter('onlyVisible', [function() {
        return function(input) {
            return _.filter(input, function(item) {
                return (item.hidden !== true);
            });
        };
    }]).
    filter('slugify', [function() {
        return function(input) {
            return _.str.slugify(input);
        };
    }]);
