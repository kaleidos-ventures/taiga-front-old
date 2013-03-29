'use strict';

angular.module('greenmine.directives.backlog', []).
    directive('gmPointsPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmPointsPopover);
            var element = angular.element(elm);

            element.popover({
                content: $("#points-popover").html(),
                html:true
            });

            element.parent().on("click", ".popover-content a.btn", function(event) {
                event.preventDefault();

                var target = angular.element(event.currentTarget);
                var points = target.data('id');

                scope.$apply(function() {
                    fn(scope, {"points": points});
                });

                element.popover('hide');
            });
        };
    }]);
