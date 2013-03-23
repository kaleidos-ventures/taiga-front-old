'use strict';

angular.module('greenmine.directives.dashboard', []).
    directive('gmUserPopover', ["$parse", function($parse) {
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
    }]).
    directive("gmNewtaskModal", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var modalElement = angular.element("#new-task-modal");

            element.on("click", attrs.uiNewtaskModal, function(event) {
                event.preventDefault();
                var target = angular.element(event.currentTarget);

                scope.newtaskForm.usId = target.scope().us.id;
                modalElement.modal()
            });

            modalElement.on("click", ".buttons .cancel", function(event) {
                event.preventDefault();
                modalElement.modal('hide');
            });

            scope.$on('close-modals', function() {
                modalElement.modal('hide');
            });
        };
    }]);
