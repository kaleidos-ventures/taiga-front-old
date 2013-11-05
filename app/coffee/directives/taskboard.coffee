dashboardModule = angular.module('greenmine.directives.taskboard', [])

gmTaskboardGraphConstructor = ($parse, rs) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "dashboard-chart")

        element.empty()
        element.append(chart)

        ctx = $("#dashboard-chart").get(0).getContext("2d")

        options =
            animation: false,
            bezierCurve: false,
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data =
            labels : _.map(scope.milestoneStats.days, (day) -> day.name)
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : _.map(scope.milestoneStats.days, (day) -> day.optimal_points)
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.milestoneStats.days, (day) -> day.open_points)
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'milestoneStats', (value) ->
        if scope.milestoneStats
            redrawChart()

dashboardModule.directive("gmTaskboardGraph", ["$parse", "resource", gmTaskboardGraphConstructor])
