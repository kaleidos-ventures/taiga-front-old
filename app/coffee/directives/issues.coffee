GmIssuesSortedByDirective = ($rootScope, $gmFilters) ->
    removeOrderingState = (element) ->
        candidates = element.parent().find(".icon-chevron-up, .icon-chevron-down")
        candidates.removeClass("icon-chevron-up")
        candidates.removeClass("icon-chevron-down")

    setStyle = (element, reverse=false) ->
        if reverse
            element.addClass("icon-chevron-up")
        else
            element.addClass("icon-chevron-down")

    getCurrentOrdering = ->
        ordering = $gmFilters.getOrdering($rootScope.projectId, "issues")

        if ordering is null
            result = {}
            result.orderBy = "status"
            result.isReverse = false
            return result

        if ordering.isReverse is undefined
            ordering.isReverse = false

        return ordering

    setCurrentOrdering = (ordering) ->
        $gmFilters.setOrdering($rootScope.projectId, "issues", ordering)

    link = (scope, element, attrs) ->
        field = attrs.gmIssuesSortedBy

        # Destructor
        element.on "$destroy", (event) ->
            element.off()

        # Event Handling
        element.on "click", (event) ->
            removeOrderingState(element)

            ordering = getCurrentOrdering()
            if ordering.orderBy == field
                ordering.isReverse = not ordering.isReverse
            else
                ordering.orderBy = field

            setCurrentOrdering(ordering)
            setStyle(element, ordering.isReverse)

            scope.$evalAsync(attrs.gmRefreshCallback)

        # Setting initial state
        initialize = _.once ->
            ordering = getCurrentOrdering()
            if ordering.orderBy == field
                setStyle(element, ordering.isReverse)

        scope.$watch "projectId", (v) ->
            initialize() if v != undefined

    return {link: link}


module = angular.module("taiga.directives.issues", ["taiga.services.filters"])
module.directive("gmIssuesSortedBy", ["$rootScope", "$gmFilters", GmIssuesSortedByDirective])
