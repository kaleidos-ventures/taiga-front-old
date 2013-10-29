GmIssuesSortDirective = ($parse) -> (scope, elm, attrs) ->
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


GmPendingIssueGraphDirective = -> (scope, elm, attrs) ->
    redrawChart = () ->
        element = angular.element elm
        countIssues = (severities, issues) ->
            counter = {}
            for severity in severities
                counter[severity.id] = 0

            for issue in issues
                if not counter[issue.severity]
                    counter[issue.severity] = 1
                else
                    counter[issue.severity] += 1

            result = []
            for severity in severities
                result.push(counter[severity.id])
            result

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
            labels : (severity.name for severity in scope.constants.severitiesList)
            datasets : [
                #Number of created bugs
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : countIssues(scope.constants.severitiesList, scope.issues)
                },
                #Number of resolved bugs
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : countIssues(scope.constants.severitiesList, _.filter(scope.issues, 'is_closed'))
                }
            ]
        }

        new Chart(ctx).Radar(data,options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


GmYourIssuesGraphDirective = -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        countIssues = (severities, issues) ->
            counter = {}
            for severity in severities
                counter[severity.id] = 0

            for issue in issues
                if not counter[issue.severity]
                    counter[issue.severity] = 1
                else
                    counter[issue.severity] += 1

            result = []
            for severity in severities
                result.push(counter[severity.id])
            result

        width = element.width()
        height = width

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "your-issues-chart")
        element.prepend(chart)

        ctx = $("#your-issues-chart").get(0).getContext("2d")

        options =
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        colors = ["#ccc", "#669933", "blue", "orange", "#CC0000"]
        counts = countIssues(scope.constants.severitiesList, scope.issues)
        data = []

        for x in [0..counts.length-1]
            data.push value:counts[x], color:colors[x]

        new Chart(ctx).Doughnut(data,options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


GmIssuesCreationGraphDirective = -> (scope, elm, attrs) ->
    redrawChart = () ->
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
            ]
        }

        new Chart(ctx).Line(data, options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


module = angular.module('greenmine.directives.issues', [])
module.directive('gmIssuesSort', ["$parse", GmIssuesSortDirective])
module.directive("gmPendingIssueGraph", GmPendingIssueGraphDirective)
module.directive("gmYourIssuesGraph", GmYourIssuesGraphDirective)
module.directive("gmIssuesCreationGraph", GmIssuesCreationGraphDirective)
