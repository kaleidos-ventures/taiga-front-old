'use strict';

angular.module('greenmine.directives.dashboard', []).
    directive('gmUserPopover', ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var fn = $parse(attrs.gmUserPopover);
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

            element.on("click", attrs.gmNewtaskModal, function(event) {
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
    }]).
    directive("gmCanvasTest", ["$parse", function($parse) {
        return function(scope, elm, atts) {
           /* var element = angular.element(elm);

            var uniqId = _.uniqueId();
            var canvasElement = $("<canvas />")
                    .attr({"width": element.width(), "height": element.height()});
            
            element.empty();
            element.append(canvasElement);
            
            var ctx = canvasElement.get(0).getContext("2d");
            
            var options = {
                animation: false,
                bezierCurve: false
            };
            
            var data = {
                labels : ["0", "1", "2", "3", "4", "5"],
                datasets : [
                    {
                        fillColor : "rgba(220,220,220,0.5)",
                        strokeColor : "rgba(220,220,220,1)",
                        pointColor : "rgba(220,220,220,1)",
                        pointStrokeColor : "#fff",
                        data : [100, 80, 60, 40, 20, 0]
                    },
                    {
                        fillColor : "rgba(151,187,205,0.5)",
                        strokeColor : "rgba(151,187,205,1)",
                        pointColor : "rgba(151,187,205,1)",
                        pointStrokeColor : "#fff",
                        data : [100, 76, 64, 36, 0, 0]
                    }
                ]
            };
            
            var chart = new Chart(ctx).Line(data, options);*/

        };
    }]);
