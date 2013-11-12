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

GmBacklogGraphDirective = ($parse) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "burndown-chart")
        element.append(chart)

        ctx = $("#burndown-chart").get(0).getContext("2d")

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

GmTaskboardGraphDirective = ($parse, rs) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "dashboard-chart")

        element.empty()
        element.append(chart)

        ctx = $("#dashboard-chart").get(0).getContext("2d")

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

module = angular.module("greenmine.directives.graphs", [])
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive("gmTaskboardGraph", ["$parse", "resource", GmTaskboardGraphDirective])
