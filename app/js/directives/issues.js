'use strict';

angular.module('greenmine.directives.issues', []).
    directive('gmIssuesSort', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            console.log(scope);

            element.on("click", ".issue-sortable-field", function(event) {
                var target = angular.element(event.currentTarget);
                if (target.data('field') === scope.sortingOrder) {
                    scope.reverse = !scope.reverse;
                } else {
                    scope.sortingOrder = target.data('field');
                    scope.reverse = false;
                }

                var icon = target.find("i");
                icon.removeClass("icon-chevron-up");
                icon.removeClass("icon-chevron-down");

                if (scope.reverse) {
                    icon.addClass("icon-chevron-up");
                } else {
                    icon.addClass("icon-chevron-down");
                }

                event.preventDefault();
                scope.$digest();
            });
        };
    }]);
