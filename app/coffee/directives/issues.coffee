
issuesModule = angular.module('greenmine.directives.issues', [])


gmIssuesSortConstructor = ($parse) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    element.on "click", ".issue-sortable-field", (event) ->
        target = angular.element(event.currentTarget)
        if target.data('field') == scope.sortingOrder
            scope.reverse = !scope.reverse
        else
            scope.sortingOrder = target.data('field')
            scope.reverse = false

        icon = target.find("i")
        icon.removeClass("icon-chevron-up")
        icon.removeClass("icon-chevron-down")

        if scope.reverse
            icon.addClass("icon-chevron-up")
        else
            icon.addClass("icon-chevron-down")

        event.preventDefault()
        scope.$digest()

issuesModule.directive('gmIssuesSort', ["$parse", gmIssuesSortConstructor]);a


gmIssueChangesConstructor = ->
    validFields = ["priority", "status", "severity", "tags", "subject", "description", "assigned_to"]
    template = _.template($("#change-template").html())

    return (scope, elm, attrs) ->
        element = angular.element(elm)

        handleField = (name, field) ->
            template(name: name, oldValue: field.old, newValue: field.new)

        elements = []

        for fieldName in validFields
            field = scope.h[fieldName]

            if field is undefined
                continue

            elements.push(handleField(fieldName, field))

        element.append(el) for el in elements

issuesModule.directive("gmIssueChanges", gmIssueChangesConstructor)
