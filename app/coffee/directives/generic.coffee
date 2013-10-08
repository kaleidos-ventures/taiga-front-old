UiEventDirective = ($parse) -> (scope, elm, attrs) ->
    events = scope.$eval(attrs.uiEvent)
    angular.forEach events,  (uiEvent, eventName) ->
        fn = $parse(uiEvent)

        elm.bind eventName,  (evt) ->
            params = Array.prototype.slice.call(arguments)
            params = params.splice(1)
            scope.$apply ->
                fn(scope, {$event: evt, $params: params})


GmFileDirective = ($parse) ->
    require: "?ngModel",
    restrict: "A",
    link: (scope, elm, attrs, ngModel) ->
        element = angular.element(elm)
        element.on 'change', (event) ->
            files = event.target.files
            if files.length == 1
                scope.$apply ->
                    ngModel.$setViewValue(files[0])


module = angular.module('greenmine.directives.generic', [])
module.directive('uiEvent', ['$parse', UiEventDirective])
module.directive('gmFile', ["$parse", GmFileDirective])
