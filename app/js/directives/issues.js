'use strict';

angular.module('greenmine.directives.issues', []).
    directive('gmIssuesSort', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);

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
    }]).
    directive('gmDeveloperPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmDeveloperPopover);
            var element = angular.element(elm);

            element.on("click", "a", function(event) {
                event.preventDefault();

                var template = _.template($("#developers-popover").html());
                element.popover({
                    content: template({"developers": scope.developers}),
                    html:true,
                    trigger: "manual",
                    placement: "left",
                    animation: false,
                    delay: 0
                });

                element.popover("show");
            });

            element.parent().on("click", ".popover-content li a", function(event) {
                event.preventDefault()
                var target = angular.element(event.currentTarget);
                var userId = target.data('dev-id');

                scope.$apply(function() {
                    scope.issue.assigned_to = parseInt(userId, 10);
                    fn(scope);
                });

                element.popover('hide');
            });
        };
    }]).
    directive('gmIssueSeverityPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmIssueSeverityPopover);
            var element = angular.element(elm);

            element.on("click", function(event) {
                event.preventDefault();

                var template = _.template($("#severity-popover").html());
                element.popover({
                    content: template({"list": scope.constants.severityList}),
                    html:true,
                    trigger: "manual",
                    placement: "right",
                    animation: false,
                    delay: 0
                });

                element.popover("show");
            });

            element.parent().on("click", ".popover-content li a", function(event) {
                event.preventDefault()
                var target = angular.element(event.currentTarget);
                var id = target.data('id');

                scope.$apply(function() {
                    scope.issue.severity = parseInt(id, 10);
                    fn(scope);
                });

                element.popover('hide');
            });
        };
    }]).
    directive('gmIssueStatusPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmIssueStatusPopover);
            var element = angular.element(elm);

            element.on("click", function(event) {
                event.preventDefault();

                var template = _.template($("#status-popover").html());
                element.popover({
                    content: template({"list": scope.constants.statusList}),
                    html: true,
                    trigger: "manual",
                    placement: "right",
                    animation: false,
                    delay: 0
                });

                element.popover("show");
            });

            element.parent().on("click", ".popover-content li a", function(event) {
                event.preventDefault()
                var target = angular.element(event.currentTarget);
                var id = target.data('id');

                scope.$apply(function() {
                    scope.issue.status = parseInt(id, 10);
                    fn(scope);
                });

                element.popover('hide');
            });
        };
    }]).
    directive('gmIssuePriorityPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmIssuePriorityPopover);
            var element = angular.element(elm);

            element.on("click", function(event) {
                event.preventDefault();

                var template = _.template($("#priority-popover").html());
                element.popover({
                    content: template({"list": scope.constants.priorityList}),
                    html:true,
                    trigger: "manual",
                    placement: "right",
                    animation: false,
                    delay: 0
                });

                element.popover("show");
            });

            element.parent().on("click", ".popover-content li a", function(event) {
                event.preventDefault()
                var target = angular.element(event.currentTarget);
                var id = target.data('id');

                scope.$apply(function() {
                    scope.issue.priority = parseInt(id, 10);
                    fn(scope);
                });

                element.popover('hide');
            });
        };
    }]).
    directive("gmIssueChanges", function() {
        var validFields = ["priority", "status", "severity", "tags"];
        var template = _.template($("#change-template").html());

        return function(scope, elm, attrs) {
            var element = angular.element(elm);

            var handleField = function(name, field) {
                var ctx = {
                    name: name,
                    oldValue: field.old,
                    newValue: field.new
                };

                return template(ctx);
            };

            _.each(validFields, function(fieldName) {
                var field = scope.h[fieldName];
                if (field !== undefined) {
                    element.append(handleField(fieldName, field));
                }
            });
        };
    });
