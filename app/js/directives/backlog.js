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

                /* Callbacks */
                var initCallback = $parse(element.data('init'));
                var cancelCallback = $parse(element.data('end-cancel'));

                element.on("click", function(event) {
                    if (modal !== undefined) {
                        scope.$apply(function() {
                            modal.modal('hide')
                            initCallback(scope);
                            modal.modal("show");
                        });

                    } else {
                        var modaltTmpl = _.str.trim(angular.element(attrs.gmModal).html());

                        modal = angular.element($.parseHTML(modaltTmpl));
                        modal.attr("id", _.uniqueId("modal-"));
                        modal.on("click", ".button-cancel", function(event) {
                            event.preventDefault();
                            scope.$apply(function() {
                                cancelCallback(scope);
                            });

                            modal.modal('hide');
                        });

                        body.append(modal);
                        scope.$apply(function() {
                            initCallback(scope);
                            $compile(modal.contents())(scope);
                        });
                        modal.modal();
                    }
                });

                scope.$on('modals:close', function() {
                    if (modal !== undefined) {
                        modal.modal('hide');
                    }
                });
            }
        };
    }]);
