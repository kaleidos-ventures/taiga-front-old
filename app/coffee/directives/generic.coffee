

AppVersionDirective = (version) -> (scope, elm, attrs) ->
    elm.text(version)


UiSelect2Directive = ->
    require: "?ngModel"
    restrict: "A"
    link: (scope, elm, attrs, ngModel) ->
        element = angular.element(elm)

        ngModel.$render = ->
            if ngModel.$modelValue
                element.val(ngModel.$modelValue.join(","))

            element.select2({tags:[], tokenSeparators: [",", " "], triggerChange:true})

        element.on 'change', ->
            ngModel.$setViewValue(arguments[0].val)
            scope.$digest()


UiEventDirective = ($parse) -> (scope, elm, attrs) ->
    events = scope.$eval(attrs.uiEvent)
    angular.forEach events,  (uiEvent, eventName) ->
        fn = $parse(uiEvent)

        elm.bind eventName,  (evt) ->
            params = Array.prototype.slice.call(arguments)
            params = params.splice(1)
            scope.$apply ->
                fn(scope, {$event: evt, $params: params})


UiParsleyDirective = ($parse, $http, url) -> (scope, elm, attrs) ->
    fn = $parse(attrs.uiParsley)

    onFormSubmit = (valid, event, form) ->
        return if not valid

        scope.$apply ->
            fn(scope, {$event:event})

    element = $(elm)
    element.parsley
        listeners: {onFormSubmit: onFormSubmit}
        validators:
            remoteuserverify: (val, opt, self) ->
                result = null

                manage = (ok) ->
                    return ->
                        constraint = _.find(self.constraints, {name: "remoteuserverify"})

                        if constraint
                            constraint.isValid = ok
                            self.isValid = null
                            self.manageValidationResult()

                finalUrl = url("user") + "?" + jQuery.param({"username": val})
                $http.head(finalUrl).success(manage(false)).error(manage(true))
                return result

        messages:
            remoteuserverify: "Username taken"


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
module.directive('appVersion', ['version', AppVersionDirective])
module.directive('uiSelect2', UiSelect2Directive)
module.directive('uiEvent', ['$parse', UiEventDirective])
module.directive('uiParsley', ['$parse', '$http', 'url', UiParsleyDirective])
module.directive('gmFile', ["$parse", GmFileDirective])
