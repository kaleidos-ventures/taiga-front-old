dashboardModule = angular.module('greenmine.directives.dashboard', [])

gmCanvasTestConstructor = ($parse) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    width = element.width()
    height = element.width()

    chart = $("<canvas />").css("width", width).css("height", height).attr("id", "dashboard-chart")

    element.empty()
    element.append(chart)

    ctx = $("#dashboard-chart").get(0).getContext("2d")

    options =
        animation: false,
        bezierCurve: false

    data =
        labels : ["0", "1", "2", "3", "4", "5"]
        datasets : [
            {
                fillColor : "rgba(220,220,220,0.5)",
                strokeColor : "rgba(220,220,220,1)",
                pointColor : "rgba(220,220,220,1)",
                pointStrokeColor : "#fff",
                data : [100, 80, 60, 40, 20, 0]
            },
            {
                fillColor : "rgba(151,187,205,0.5)",
                strokeColor : "rgba(151,187,205,1)",
                pointColor : "rgba(151,187,205,1)",
                pointStrokeColor : "#fff",
                data : [100, 76, 64, 36, 0, 0]
            }
        ]

    new Chart(ctx).Line(data, options)

dashboardModule.directive("gmCanvasTest", ["$parse", gmCanvasTestConstructor])
