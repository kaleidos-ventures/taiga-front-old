'use strict';

angular.module('greenmine.directives.common', []).
    directive('gmHeaderMenu', ["$rootScope", function($rootScope) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var menuSection = $rootScope.pageSection;

            element.find(".selected").removeClass("selected");
            if (menuSection === "backlog") {
                element.find("li.backlog").addClass("selected");
                element.find("li.dashboard").show();
            } else if(menuSection === "dashboard") {
                element.find("li.dashboard").addClass("selected");
                element.find("li.dashboard").show();
            } else if(menuSection == "issues") {
                element.find("li.issues").addClass("selected");
            } else if (menuSection === "wiki") {
                element.find("li.wiki").addClass("selected");
            } else {
                element.hide();
            }
        };
    }]).
    directive("gmBreadcrumb", ["$rootScope", function($rootScope) {
        return function(scope, elm, attrs) {
            var breadcrumb = $rootScope.pageBreadcrumb;

            if (breadcrumb !== undefined) {
                var element = angular.element(elm);
                var total = breadcrumb.length-1;

                element.empty();
                _.each(breadcrumb, function(item, index) {
                    element.append(angular.element('<span class="title-item"></span>').text(item));
                    if (index !== total) {
                        element.append(angular.element('<span class="separator"> &rsaquo; </span>'));
                    }
                });
            }
        };
    }]).
    directive('gmColorizeTag', function() {
        return function(scope, elm, attrs) {
            var element = angular.element(elm), hash;
            if (_.isObject(scope.tag)) {
                hash = hex_sha1(scope.tag.name.toLowerCase());
            } else {
                hash = hex_sha1(scope.tag.toLowerCase());
            }

            var color = hash
                .substring(0,6)
                .replace('8','0')
                .replace('9','1')
                .replace('a','2')
                .replace('b','3')
                .replace('c','4')
                .replace('d','5')
                .replace('e','6')
                .replace('f','7');

            element.css('background-color', '#' + color);
        };
    }).
    directive("gmRemovePopover", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var fn = $parse(attrs.gmRemovePopover);
            var templateSelector = element.data('template-selector');
            var ctxLookup = element.data('context');
            var placement = element.data('placement') || 'left';

            element.on("click", function(event) {
                event.preventDefault();

                var template = _.template($(templateSelector).html())
                var ctx = {}

                ctx[ctxLookup] = scope[ctxLookup];

                element.popover({
                    content: template(ctx),
                    html:true,
                    trigger: "manual",
                    placement: placement
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
    directive("gmPreviewPopover", ['$parse', function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var isOpened = false;

            var templateSelector = element.data('template-selector');
            var ctxLookup = element.data('context');
            var placement = element.data('placement') || 'left';

            element.on("click", function(event) {
                event.preventDefault();

                if (isOpened) {
                    isOpened = false;
                    element.popover("hide");
                } else {
                    var template = _.template($(templateSelector).html());
                    isOpened = true;

                    var ctx = {}
                    ctx[ctxLookup] = scope[ctxLookup];

                    element.popover({
                        content: template(ctx),
                        html:true,
                        trigger: "manual",
                        placement: placement
                    });

                    element.popover("show");
                }
            });
        };
    }]).
    directive("gmKalendae", function() {
        return {
            require: "?ngModel",
            link: function(scope, elm, attrs, ngModel) {
                var element = angular.element(elm);
                var options = {
                    format: "YYYY-MM-DD"
                };

                var kalendae = new Kalendae.Input(element.get(0), options);
                element.data('kalendae', kalendae);

                kalendae.subscribe('change', function(date, action) {
                    var self = this;
                    scope.$apply(function() {
                        ngModel.$setViewValue(self.getSelected())
                    });
                });
            }
        };
    }).
    directive("uiSortable", function() {
        var uiConfig = {};

        return {
            require: '?ngModel',
            link: function(scope, element, attrs, ngModel) {
                var onReceive, onRemove, onStart, onUpdate, opts, onStop;

                opts = angular.extend({}, uiConfig.sortable);
                opts.connectWith = attrs.uiSortable;

                if (ngModel) {
                    ngModel.$render = function() {
                        element.sortable( "refresh" );
                    };

                    onStart = function(e, ui) {
                        // Save position of dragged item
                        ui.item.sortable = { index: ui.item.index() };
                        //console.log("onStart", ui.item.index());
                    };

                    onUpdate = function(e, ui) {
                        // For some reason the reference to ngModel in stop() is wrong
                        // console.log("onUpdate", ngModel.$modelValue);
                        ui.item.sortable.model = ngModel;
                        ui.item.sortable.scope = scope;
                    };

                    onReceive = function(e, ui) {
                        //console.log("onReceive", ui.item.sortable.moved);

                        ui.item.sortable.relocate = true;
                        //ngModel.$modelValue.splice(ui.item.index(), 0, ui.item.sortable.moved);
                        //ngModel.$viewValue.splice(ui.item.index(), 0, ui.item.sortable.moved);

                        //scope.$digest()
                        //scope.$broadcast("backlog-resort");
                    };

                    onRemove = function(e, ui) {
                        if (ngModel.$modelValue.length === 1) {
                            ui.item.sortable.moved = ngModel.$modelValue.splice(0, 1)[0];
                        } else {
                            ui.item.sortable.moved =  ngModel.$modelValue.splice(ui.item.sortable.index, 1)[0];
                        }

                        //console.log("onRemove", ui.item.sortable.moved);
                    };

                    onStop = function(e, ui) {
                        // digest all prepared changes
                        // console.log("onStop", ui.item.sortable.moved)
                        //if (ui.item.sortable.moved === undefined) {
                        //    scope.$broadcast("backlog-resort");
                        //} else {
                        if (ui.item.sortable.model && !ui.item.sortable.relocate) {
                            // Fetch saved and current position of dropped element
                            var end, start;
                            start = ui.item.sortable.index;
                            end = ui.item.index();

                            // Reorder array and apply change to scope
                            ui.item.sortable.model.$modelValue.splice(end, 0, ui.item.sortable.model.$modelValue.splice(start, 1)[0]);
                            //scope.$broadcast("sortable:changed");
                            scope.$emit("sortable:changed");
                        } else {
                            //if (scope.status !== undefined) {
                            //    ui.item.sortable.moved.status = scope.status.id;
                            //}

                            scope.$apply(function() {
                                ui.item.sortable.moved.order = ui.item.index();
                                ui.item.sortable.model.$modelValue.splice(ui.item.index(), 0, ui.item.sortable.moved);
                            });
                            scope.$apply(function() {
                                //ui.item.sortable.scope.$broadcast("sortable:changed");
                                ui.item.sortable.scope.$emit("sortable:changed");
                                scope.$emit("sortable:changed");
                            });
                        }

                        scope.$apply();
                    };

                    // If user provided 'start' callback compose it with onStart function
                    opts.start = (function(_start){
                        return function(e, ui) {
                            onStart(e, ui);
                            if (typeof _start === "function")
                                _start(e, ui);
                        }
                    })(opts.start);

                    // If user provided 'start' callback compose it with onStart function
                    opts.stop = (function(_stop){
                        return function(e, ui) {
                            onStop(e, ui);
                            if (typeof _stop === "function")
                                _stop(e, ui);
                        }
                    })(opts.stop);

                    // If user provided 'update' callback compose it with onUpdate function
                    opts.update = (function(_update){
                        return function(e, ui) {
                            onUpdate(e, ui);
                            if (typeof _update === "function")
                                _update(e, ui);
                        }
                    })(opts.update);

                    // If user provided 'receive' callback compose it with onReceive function
                    opts.receive = (function(_receive){
                        return function(e, ui) {
                            onReceive(e, ui);
                            if (typeof _receive === "function")
                                _receive(e, ui);
                        }
                    })(opts.receive);

                    // If user provided 'remove' callback compose it with onRemove function
                    opts.remove = (function(_remove){
                        return function(e, ui) {
                            onRemove(e, ui);
                            if (typeof _remove === "function")
                                _remove(e, ui);
                        };
                    })(opts.remove);
                }

                // Create sortable
                element.sortable(opts);
            }
        };
    }).
    directive('gmPopover', ['$parse', '$compile', function($parse, $compile) {
        var createContext = function(scope, element) {
            var context = (element.data('ctx') || "").split(",");
            var data = {_scope: scope};

            _.each(context, function(key) {
                key = _.str.trim(key);
                data[key] = scope[key];
            });

            return data;
        };

        return {
            restrict: "A",
            link: function(scope, elm, attrs) {
                var fn = $parse(attrs.gmPopover);
                var element = angular.element(elm);
                var autoHide = element.data('auto-hide')

                var closeHandler = function() {
                    var state = element.data('state');

                    if (state === "closing") {
                        element.popover('hide');
                        element.data('state', 'closed');
                    }
                };

                element.on("click", function(event) {
                    event.preventDefault();

                    var context = createContext(scope, element);
                    var template = _.str.trim($(element.data('tmpl')).html());
                    template = angular.element($.parseHTML(template));


                    scope.$apply(function() {
                        $compile(template)(scope);
                    });

                    element.popover({
                        content: template,
                        html:true,
                        animation: false,
                        delay: 0,
                        trigger: "manual"
                    });

                    element.popover("show");

                    if (autoHide !== undefined) {
                        element.data('state', 'closing');
                        _.delay(closeHandler, 2000);
                    }
                });

                var parentElement = element.parent();
                var acceptSelector = element.data('accept-selector') || '.popover-content .btn-accept';
                var cancelSelector = element.data('cancel-selector') || '.popover-content .btn-cancel';

                parentElement.on("click", acceptSelector, function(event) {
                    event.preventDefault();

                    var context = createContext(scope, element);
                    var target = angular.element(event.currentTarget);
                    var id = angular.element(event.currentTarget).data('id');

                    context = _.extend(context, {"selectedObj": target.scope().obj});
                    scope.$apply(function() {
                        fn(scope, context);
                    });

                    element.popover('hide');
                });

                parentElement.on("click", cancelSelector, function(event) {
                    element.popover('hide');
                });

                if (autoHide) {
                    parentElement.on("mouseleave", ".popover", function(event) {
                        var target = angular.element(event.currentTarget);
                        element.data('state', 'closing');
                        _.delay(closeHandler, 1000);
                    });

                    parentElement.on("mouseenter", ".popover", function(event) {
                        var target = angular.element(event.currentTarget);
                        element.data('state', 'open');
                    });
                }
            }
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
