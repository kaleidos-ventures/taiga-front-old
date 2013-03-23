'use strict';

angular.module('greenmine.directives.dashboard', []).
    directive('uiUserPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.uiUserPopover);
            var element = angular.element(elm);
            var selectedTarget = element.find(".buttons a");

            selectedTarget.popover({
                content: $("#developers-popover").html(),
                html:true
            });

            element.on("click", ".popover-content li a", function(event) {
                event.preventDefault()
                var target = angular.element(event.currentTarget);
                var userId = target.data('dev-id');

                scope.task.assigned_to = _.find(scope.developers, function(item) {
                    return item.id == parseInt(userId, 10);
                });

                fn(scope);

                selectedTarget.popover('hide');
                scope.$digest();
            });
        };
    }]);
