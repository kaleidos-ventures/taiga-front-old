'use strict';

angular.module('greenmine.directives.generic', []).
    directive('appVersion', ['version', function(version) {
        return function(scope, elm, attrs) {
            elm.text(version);
        };
    }]).

    directive('uiSelected', ['$parse', function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var currentValue = element.val();
            var compareValue = scope.$eval(attrs.uiSelected);
            console.log(currentValue, compareValue);
        };
    }]).
    directive('uiEvent', ['$parse', function ($parse) {
        return function(scope, elm, attrs) {
            var events = scope.$eval(attrs.uiEvent);
            angular.forEach(events, function (uiEvent, eventName) {
                var fn = $parse(uiEvent);
                elm.bind(eventName, function (evt) {
                    var params = Array.prototype.slice.call(arguments);
                    //  Take out first paramater (event object);
                    params = params.splice(1);
                    scope.$apply(function () {
                        fn(scope, {$event: evt, $params: params});
                    });
                });
            });
        };
    }]).
    directive("uiMultipleModal", ['$parse', function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.uiMultipleModal);
            var element = $(elm);

            var targetSelector = element.data('target');
            var itemSelector = element.data('items');

            var modal = $(targetSelector);
            var targetScope;

            element.on("click", itemSelector, function(event) {
                targetScope = angular.element(event.currentTarget).scope();
                modal.modal("show");
            });

            modal.on('click', '.btn-primary', function(event) {
                modal.modal('hide');
                _.delay(function() {
                    fn(targetScope);
                }, 500);
            });
        };
    }]).
    directive("uiSimpleModal", ['$parse', function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.uiSimpleModal);

            var element = $(elm);
            var modal = $(element.data('target'));

            element.on('click', function(event) {
                if (!element.hasClass("disabled")) {
                    event.stopPropagation();
                    modal.modal("show");
                }
            });

            modal.on('click', '.btn-primary', function(event) {
                modal.modal('hide');
                scope.$apply(function() {
                    fn(scope);
                });
            });
        };
    }]).
    directive("uiSpinjs", ["$parse", function($parse) {
        var opts = {
            lines: 12, // The number of lines to draw
            length: 6, // The length of each line
            width: 2, // The line thickness
            radius: 5, // The radius of the inner circle
            corners: 1, // Corner roundness (0..1)
            rotate: 0, // The rotation offset
            color: '#000', // #rgb or #rrggbb
            speed: 2, // Rounds per second
            trail: 30, // Afterglow percentage
            shadow: false, // Whether to render a shadow
            hwaccel: true, // Whether to use hardware acceleration
            className: 'spinner', // The CSS class to assign to the spinner
            zIndex: 2e9, // The z-index (defaults to 2000000000)
            top: 'auto', // Top position relative to parent in px
            left: 'auto' // Left position relative to parent in px
        };

        return function(scope, elm, attrs) {
            var target = $(elm);
            var spinner = new Spinner(opts).spin();
            target.append(spinner.el);

            var watchModelName = $parse(attrs.uiSpinjs)();

            if (watchModelName === undefined) {
                return;
            }

            scope.$watch(watchModelName, function(newvalue, oldvalue) {
                if (newvalue === true) {
                    spinner.stop();
                    target.hide();
                }
            });
        };
    }]).
    directive('uiParsley', ['$parse', '$http', 'url', function($parse, $http, url) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.uiParsley);

            var onFormSubmit = function(valid, event, form) {
                if (!valid) return;
                scope.$apply(function() {
                    fn(scope, {$event:event});
                });
            };

            var element = $(elm);
            element.parsley({
                listeners: {onFormSubmit: onFormSubmit},
                validators: {
                    remoteuserverify: function(val, opt, self) {
                        var result = null;

                        var manage = function(ok) {
                            return function () {
                                var constraint = _.find(self.constraints, function(item) {
                                    return item.name == "remoteuserverify";
                                });

                                if (constraint)  {
                                    constraint.isValid = ok;
                                    self.isValid = null;
                                    self.manageValidationResult();
                                }
                            };
                        };

                        var finalUrl = url("user") + "?" + jQuery.param({"username": val});
                        $http.head(finalUrl).success(manage(false)).error(manage(true));
                        return result;
                    }
                },
                messages: {
                    remoteuserverify: "Username taken"
                }
            });
        };
    }]).
    directive("uiContentEditable", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = $(elm);
            element.attr('contenteditable', 'true');
            element.attr('spellcheck', 'false');

            element.on("keydown", function(event) {
                if (event.keyCode == 13) {
                    event.preventDefault();
                }
            });
        };
    }]);
