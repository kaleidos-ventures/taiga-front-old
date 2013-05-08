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

issuesModule.directive('gmIssuesSort', ["$parse", gmIssuesSortConstructor])


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

gmPendingIssueGraphConstructor = ->
    return (scope, elm, attrs) ->

        element = angular.element(elm)

        width = element.width()
        height = width

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "issues-chart")
        element.append(chart)

        ctx = $("#issues-chart").get(0).getContext("2d")

        options =
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = {
            labels : ["Wishlist","Minor","Normal","Important","Critical"],
            datasets : [
                #Number of created bugs
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : [100,80,60,80,100]
                },
                #Number of resolved bugs
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : [100,60,40,50,100]
                }
            ]
        }

        new Chart(ctx).Radar(data,options)

issuesModule.directive("gmPendingIssueGraph", gmPendingIssueGraphConstructor)

gmYourIssuesGraphConstructor = ->
    return (scope, elm, attrs) ->

        element = angular.element(elm)

        width = element.width()
        height = width

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "your-issues-chart")
        element.prepend(chart)

        ctx = $("#your-issues-chart").get(0).getContext("2d")

        options =
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = [
            # Wishlist
            {
                value: 30,
                color:"#ccc"
            },
            # Minor
            {
                value : 50,
                color : "#669933"
            },
            # Normal
            {
                value : 100,
                color : "blue"
            },
            # Important
            {
                value : 40,
                color : "orange"
            },
            # Critical
            {
                value : 120,
                color : "#CC0000"
            }

        ]

        new Chart(ctx).Doughnut(data,options);

issuesModule.directive("gmYourIssuesGraph", gmYourIssuesGraphConstructor)

gmIssuesCreationGraphConstructor = ->
    return (scope, elm, attrs) ->

        element = angular.element(elm)

        width = element.width()
        height = 320

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "issues-creation-chart")
        element.prepend(chart)

        ctx = $("#issues-creation-chart").get(0).getContext("2d")

        options =
            animation: false,
            bezierCurve: false,
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = {
            labels : ["Sprint1","Sprint2","Sprint3","Sprint4","Sprint5","Sprint6"],
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : [10, 15, 30, 40, 20, 10]
                }
                ##,
                #{
                #    fillColor : "rgba(102,153,51,0.3)",
                #    strokeColor : "rgba(102,153,51,1)",
                #    pointColor : "rgba(255,255,255,1)",
                #    data : [100,92,68,45,19,0]
                #}
            ]
        }

        new Chart(ctx).Line(data, options)

issuesModule.directive("gmIssuesCreationGraph", gmIssuesCreationGraphConstructor)
