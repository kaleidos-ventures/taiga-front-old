setStyle = (element, reverse=false) ->
    if reverse
        element.addClass("icon-chevron-up")
    else
        element.addClass("icon-chevron-down")

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

            target.parent().children().removeClass("icon-chevron-down")
            target.parent().children().removeClass("icon-chevron-up")

            setStyle target, scope.sortingReverse

            event.preventDefault()

GmIssuesSortedByDirective = (SelectedTags) ->
    link: (scope, element, attrs) ->
        if SelectedTags.issues_order.getField() == attrs.field
            setStyle element, SelectedTags.issues_order.isReverse()

module = angular.module('taiga.directives.issues', [])
module.directive('gmIssuesSort', ["$parse", GmIssuesSortDirective])
module.directive('gmIssuesSortedBy', ["SelectedTags", GmIssuesSortedByDirective])
