'use strict';

angular.module('greenmine.directives.common', []).
    directive('gmHeaderMenu', ["$rootScope", function($rootScope) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var menuSection = $rootScope.pageSection;

            console.log($rootScope);
            console.log(menuSection);

            element.find(".selected").removeClass("selected");
            if (menuSection === "backlog") {
                element.find("li.backlog").addClass("selected");
                element.find("li.dashboard").show();
            } else if(menuSection === "dashboard") {
                element.find("li.dashboard").addClass("selected");
                element.find("li.dashboard").show();
            }
        };
    }]).
    directive("gmBreadcrumb", ["$rootScope", function($rootScope) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);
            var breadcrumb = $rootScope.pageBreadcrumb;
            var total = breadcrumb.length-1;

            element.empty();
            _.each(breadcrumb, function(item, index) {
                element.append(angular.element('<span class="title-item"></span>').text(item));
                if (index !== total) {
                    element.append(angular.element('<span class="separator"> &rsaquo; </span>'));
                }
            });

        };
    }]);

