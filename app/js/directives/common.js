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
            var element = angular.element(elm);
            var hash = hex_sha1(scope.tag.name);
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
    });

