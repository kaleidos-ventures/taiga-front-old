angular.module('greenmine.filters.common', []).
    filter('onlyVisible', [function() {
        return function(input) {
            return _.filter(input, function(item) {
                return (item.__hidden !== true);
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
    }]).
    filter("momentFormat", [function() {
        return function(input, format) {
            return moment(input).format(format);
        };
    }]).
    filter("lowercase", [function() {
        return function(input) {
            return input.toLowerCase();
        };
    }]);
