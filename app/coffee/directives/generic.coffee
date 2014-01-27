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



GmFilesDirective = ($parse) ->
    restrict: "A",
    link: (scope, elm, attrs) ->
        scope[attrs["gmFiles"]] = []
        element = angular.element(elm)
        element.on 'change', (event) ->
            files = _.map(event.target.files, (x)->x)
            if files.length >= 1
                scope.$apply ->
                    if scope[attrs["gmFiles"]].length == 0
                        scope[attrs["gmFiles"]] = files
                    else
                        scope[attrs["gmFiles"]] = scope[attrs["gmFiles"]].concat(files)


module = angular.module('taiga.directives.generic', [])
module.directive('gmFile', ["$parse", GmFileDirective])
module.directive('gmFiles', ["$parse", GmFilesDirective])
