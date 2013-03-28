angular.module('greenmine.filters.common', []).
    filter('onlyVisible', [function() {
        return function(input) {
            return _.filter(input, function(item) {
                return (item.hidden !== true);
            });
        };
    }]).
    filter('truncate', function() {
        return function(input, num) {
            if (num === undefined) num =  25;
            return _.str.prune(input, num);
        };
    }).
    filter('slugify', [function() {
        return function(input) {
            return _.str.slugify(input);
        };
    }]);
