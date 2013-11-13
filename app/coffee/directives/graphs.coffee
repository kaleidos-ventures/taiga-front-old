# Copyright 2013 Andrey Antukh <niwi@niwi.be>

# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GmBacklogGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "burndown-chart")
        element.empty()
        element.append(chart)
        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            bezierCurve: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0


        data =
            labels : _.map(scope.projectStats.milestones, (ml) -> ml.name)
            datasets : [
                {
                    fillColor : "rgba(0,0,0,0)",
                    strokeColor : "rgba(0,0,0,1)",
                    pointColor : "rgba(0,0,0,0)",
                    pointStrokeColor : "rgba(0,0,0,0)",
                    data : _.map(scope.projectStats.milestones, (ml) -> 0)
                },
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : _.map(scope.projectStats.milestones, (ml) -> ml.optimal)
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.filter(_.map(scope.projectStats.milestones, (ml) -> ml.evolution), (evolution) -> evolution?)
                },
                {
                    fillColor : "rgba(153,51,51,0.3)",
                    strokeColor : "rgba(153,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.projectStats.milestones, (ml) -> -ml['team-increment'])
                },
                {
                    fillColor : "rgba(255,51,51,0.3)",
                    strokeColor : "rgba(255,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.projectStats.milestones, (ml) -> -ml['team-increment']-ml['client-increment'])
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'projectStats', (value) ->
        if scope.projectStats
            redrawChart()

GmTaskboardGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "dashboard-chart")
        element.empty()
        element.append(chart)
        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            bezierCurve: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0

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

GmIssuesPieGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        height = width
        chart = $("<canvas />").attr("width", width).attr("height", height)

        element.empty()
        element.append(chart)

        ctx = chart.get(0).getContext("2d")

        options =
            animateRotate: false
            animateScale: true
            animationEasing : "easeOutQuart"

        data = _.map(_.values(dataToDraw), (x) ->
            {
                value : x['count'],
                color: x['color']
            }
        )

        new Chart(ctx).Pie(data, options)

    scope.$watch attrs.gmIssuesPieGraph, () ->
        value = scope.$eval(attrs.gmIssuesPieGraph)
        if value
            redrawChart(value)

GmIssuesAccumulatedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)


    redrawChart = (dataToDraw) ->
        vectorsSum = (vector1, vector2) ->
            result = []
            for x in [0..27]
                result[x] = vector1[x] + vector2[x]
            return result

        width = element.width()
        height = width/2
        chart = $("<canvas />").attr("width", width).attr("height", height)

        element.empty()
        element.append(chart)

        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0


        data = {}
        data.labels = _.map([27..0], (x) ->
            moment().subtract('days', x).date()
        )
        data.datasets = []
        for row in dataToDraw
            if accumulated_data?
                accumulated_data = vectorsSum(accumulated_data, row.data)
            else
                accumulated_data = row.data

            color = $.Color(row.color)

            data.datasets.unshift({
                fillColor: color.alpha(0.5).toRgbaString()
                strokeColor: color.toRgbaString()
                pointColor: color.alpha(0.5).toRgbaString()
                pointStrokeColor: color.toRgbaString()
                data: accumulated_data
            })

        new Chart(ctx).Line(data, options)

    scope.$watch attrs.gmIssuesAccumulatedGraph, () ->
        value = scope.$eval(attrs.gmIssuesAccumulatedGraph)
        if value
            redrawChart(_.values(value))

GmIssuesOpenClosedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        height = width/2
        chart = $("<canvas />").attr("width", width).attr("height", height)

        element.empty()
        element.append(chart)

        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            scaleStepWidth: 1
            datasetFillXAxis: 0
            datasetFillYAxis: 0


        data = {}
        data.labels = _.map([27..0], (x) ->
            moment().subtract('days', x).date()
        )
        green = $.Color('green')
        red = $.Color('red')
        data.datasets = [
            {
                fillColor: green.alpha(0.5).toRgbaString()
                strokeColor: green.toRgbaString()
                data: dataToDraw['closed']
            },
            {
                fillColor: red.alpha(0.5).toRgbaString()
                strokeColor: red.toRgbaString()
                data: dataToDraw['open']
            }
        ]

        new Chart(ctx).Bar(data, options)

    scope.$watch attrs.gmIssuesOpenClosedGraph, () ->
        value = scope.$eval(attrs.gmIssuesOpenClosedGraph)
        if value
            redrawChart(value)

GmIssuesOpenProgressionGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        height = width/2
        chart = $("<canvas />").attr("width", width).attr("height", height)

        element.empty()
        element.append(chart)

        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0


        data = {}
        data.labels = _.map([27..0], (x) ->
            moment().subtract('days', x).date()
        )
        color = $.Color('red')
        data.datasets = [{
            fillColor: color.alpha(0.5).toRgbaString()
            strokeColor: color.toRgbaString()
            pointColor: color.alpha(0.5).toRgbaString()
            pointStrokeColor: color.toRgbaString()
            data: dataToDraw
        }]

        new Chart(ctx).Line(data, options)

    scope.$watch attrs.gmIssuesOpenProgressionGraph, () ->
        value = scope.$eval(attrs.gmIssuesOpenProgressionGraph)
        if value
            redrawChart(value)

module = angular.module("greenmine.directives.graphs", [])
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive("gmTaskboardGraph", GmTaskboardGraphDirective)
module.directive("gmIssuesPieGraph", GmIssuesPieGraphDirective)
module.directive("gmIssuesAccumulatedGraph", GmIssuesAccumulatedGraphDirective)
module.directive("gmIssuesOpenClosedGraph", GmIssuesOpenClosedGraphDirective)
module.directive("gmIssuesOpenProgressionGraph", GmIssuesOpenProgressionGraphDirective)
