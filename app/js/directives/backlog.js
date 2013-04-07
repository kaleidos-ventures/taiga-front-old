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
    }]).
    directive("gmModal", ["$parse", "$compile", function($parse, $compile) {
        return {
            restrict: "A",
            link: function(scope, elm, attrs) {
                var modal, element = angular.element(elm);
                var body = angular.element("body");

                element.on("click", function(event) {
                    if (modal !== undefined) {
                        modal.modal('hide')
                        modal.remove();
                    }

                    var modaltTmpl = _.str.trim(angular.element(attrs.gmModal).html());

                    modal = angular.element($.parseHTML(modaltTmpl));
                    modal.attr("id", _.uniqueId("modal-"));
                    modal.addClass("modal-instance");

                    body.append(modal);

                    scope.$apply(function() {
                        scope.editUs(scope.us);
                        $compile(modal.contents())(scope);
                    });

                    modal.modal();
                });

                scope.$on('modals:close', function() {
                    if (modal !== undefined) {
                        modal.modal('hide');
                    }
                });
            }
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
                    if (scope.form) {
                        if (scope.form.revert !== undefined) {
                            scope.form.revert();
                        } else {
                            scope.form = {};
                        }
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
