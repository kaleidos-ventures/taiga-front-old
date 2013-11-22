GmIssuesSortDirective = ($parse) ->
    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        callback = $parse(attrs.gmIssuesSort)

        element.on "click", ".issue-sortable-field", (event) ->
            target = angular.element(event.currentTarget)
            if target.data('field') == scope.sortingOrder
                scope.sortingReverse = !scope.sortingReverse
            else
                scope.sortingOrder = target.data('field')
                scope.sortingReverse = false

            locals = {
                field: target.data('field')
                reverse: scope.sortingReverse
            }

            scope.$apply ->
                callback(scope, locals)

            icon = target.find("i")
            icon.removeClass("icon-chevron-up")
            icon.removeClass("icon-chevron-down")

            if scope.sortingReverse
                icon.addClass("icon-chevron-up")
            else
                icon.addClass("icon-chevron-down")

            event.preventDefault()

module = angular.module('greenmine.directives.issues', [])
module.directive('gmIssuesSort', ["$parse", GmIssuesSortDirective])
