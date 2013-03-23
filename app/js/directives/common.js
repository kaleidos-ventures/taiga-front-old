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
    }]);

