'use strict';

angular.module('greenmine.directives.backlog', []).
    directive("gmUsremovePopover", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var fn = $parse(attrs.gmUsremovePopover);

            element.on("click", function(event) {
                event.preventDefault();

                var template = _.template($("#us-remove-popover").html())
                element.popover({
                    content: template({us: scope.us}),
                    html:true,
                    animation: false,
                    delay: 0,
                    trigger: "manual"
                });

                element.popover("show");
            });

            var parentElement = element.parent();

            parentElement.on("click", ".popover-content .btn-delete", function(event) {
                scope.$apply(function() {fn(scope); });
                element.popover('hide');
            });

            parentElement.on("click", ".popover-content .btn-cancel", function(event) {
                element.popover('hide');
            });
        };
    }]);
