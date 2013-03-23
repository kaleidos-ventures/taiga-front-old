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
            } else if(menuSection === "dashboard") {
                element.find("li.bugs").addClass("selected");
            }
        };
    }]);

