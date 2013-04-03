'use strict';

angular.module('greenmine.directives.backlog', []).
    directive('gmPointsPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmPointsPopover);
            var element = angular.element(elm);

            element.on("click", function(event) {
                event.preventDefault();

                element.popover({
                    content: $("#points-popover").html(),
                    html:true,
                    animation: false,
                    delay: 0,
                    trigger: "manual"
                });

                element.popover("show");
            });

            element.parent().on("click", ".popover-content a.btn", function(event) {
                event.preventDefault();

                var target = angular.element(event.currentTarget);
                var pointId = target.data('id');

                scope.$apply(function() {
                    fn(scope, {"points": pointId});
                });

                element.popover('hide');
            });
        };
    }]).
    directive("gmUspreviewPopover", ['$parse', '$compile', function($parse, $compile) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var isOpened = false

            element.on("click", function(event) {
                event.preventDefault();

                if (isOpened) {
                    isOpened = false;
                    element.popover("hide");
                } else {
                    var template = _.template($("#us-preview-popover").html());
                    isOpened = true;

                    element.popover({
                        content: template({us: scope.us}),
                        html:true,
                        animation: false,
                        delay: 0,
                        trigger: "manual"
                    });

                    element.popover("show");
                }
            });
        };
    }]).
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
    }]).
    directive("gmNewUsModal", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var modalElement = angular.element(attrs.gmNewUsModal);

            element.on("click", function(event) {
                scope.$apply(function() {
                    scope.editUs(scope.us);
                });

                event.preventDefault();
                modalElement.modal()
            });

            modalElement.on("click", ".button-cancel", function(event) {
                scope.$apply(function() {
                    if (scope.form.revert !== undefined) {
                        scope.form.revert();
                    } else {
                        scope.form = {};
                    }
                });

                event.preventDefault();
                modalElement.modal('hide');
            });

            scope.$on('modals:close', function() {
                modalElement.modal('hide');
            });
        };
    }]);
