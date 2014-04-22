# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


GmBacklogGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        element.height(width/6)

        milestones = _.map(scope.projectStats.milestones, (ml) -> ml.name)
        milestonesRange = [0..(milestones.length - 1)]
        data = []
        zero_line = _.map(dataToDraw.milestones, (ml) -> 0)
        data.push({
            data: _.zip(milestonesRange, zero_line)
            lines:
                fillColor : "rgba(0,0,0,0)"
            points:
                show: false
        })
        optimal_line = _.map(dataToDraw.milestones, (ml) -> ml.optimal)
        data.push({
            data: _.zip(milestonesRange, optimal_line)
            lines:
                fillColor : "rgba(120,120,120,0.2)"
        })
        evolution_line = _.filter(_.map(dataToDraw.milestones, (ml) -> ml.evolution), (evolution) -> evolution?)
        data.push({
            data: _.zip(milestonesRange, evolution_line)
            lines:
                fillColor : "rgba(102,153,51,0.3)"
        })
        team_increment_line = _.map(dataToDraw.milestones, (ml) -> -ml['team-increment'])
        data.push({
            data: _.zip(milestonesRange, team_increment_line)
            lines:
                fillColor : "rgba(153,51,51,0.3)"
        })
        client_increment_line = _.map(dataToDraw.milestones, (ml) -> -ml['team-increment']-ml['client-increment'])
        data.push({
            data: _.zip(milestonesRange, client_increment_line)
            lines:
                fillColor : "rgba(255,51,51,0.3)"
        })

        colors = [
            "rgba(0,0,0,1)"
            "rgba(120,120,120,0.2)"
            "rgba(102,153,51,1)"
            "rgba(153,51,51,1)"
            "rgba(255,51,51,1)"
        ]

        options =
            grid:
                borderWidth: { top: 0, right: 1, left:0, bottom: 0 }
                borderColor: '#ccc'
            xaxis:
                ticks: _.zip(milestonesRange, milestones)
                axisLabelUseCanvas: true
                axisLabelFontSizePixels: 12
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif'
                axisLabelPadding: 5
            series:
                shadowSize: 0
                lines:
                    show: true
                    fill: true
                points:
                    show: true
                    fill: true
                    radius: 4
                    lineWidth: 2
            colors: colors

        element.empty()
        element.plot(data, options).data("plot")

    scope.$watch 'projectStats', (value) ->
        if scope.projectStats
            redrawChart(scope.projectStats)

GmTaskboardGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        element.height(240)

        days = _.map(dataToDraw, (x) -> moment(x.day))

        data = []
        data.unshift({
            data: _.zip(days, _.map(dataToDraw, (d) -> d.optimal_points))
            lines:
                fillColor : "rgba(120,120,120,0.2)"
        })
        data.unshift({
            data: _.zip(days, _.map(dataToDraw, (d) -> d.open_points))
            lines:
                fillColor : "rgba(102,153,51,0.3)"
        })

        options =
            grid:
                borderWidth: { top: 0, right: 1, left:0, bottom: 0 }
                borderColor: '#ccc'
            xaxis:
                tickSize: [1, "day"]
                min: days[0]
                max: _.last(days)
                mode: "time"
                daysNames: days
                axisLabel: 'Day'
                axisLabelUseCanvas: true
                axisLabelFontSizePixels: 12
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif'
                axisLabelPadding: 5
            yaxis:
                min: 0
            series:
                shadowSize: 0
                lines:
                    show: true
                    fill: true
                points:
                    show: true
                    fill: true
                    radius: 4
                    lineWidth: 2
            colors: ["rgba(102,153,51,1)", "rgba(120,120,120,0.2)"]

        element.empty()
        element.plot(data, options).data("plot")

    scope.$watch 'milestoneStats', (value) ->
        if scope.milestoneStats
            redrawChart(scope.milestoneStats.days)

GmIssuesPieGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        element.height(width)
        data = _.map(_.values(dataToDraw), (d) -> { data: d.count, label: d.name})
        options =
            series:
                pie:
                    show: true
                    radius: 100
                    label:
                        show: true
                        radius: 3/4
                        formatter: (label, slice) ->
                            "<div class='pieLabelText'>#{label}<br/>#{slice.data[0][1]}</div>"
                        background:
                            opacity: 0.5
                            color: 'black'
            legend:
                show: false
            colors: _.map(_.values(dataToDraw), (d) -> d.color)


        element.empty()
        element.plot(data, options).data("plot")


    scope.$watch attrs.gmIssuesPieGraph, () ->
        value = scope.$eval(attrs.gmIssuesPieGraph)
        if value and scope.showGraphs
            redrawChart(value)
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesPieGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(value)
            , 200)

GmIssuesAccumulatedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)


    redrawChart = (dataToDraw) ->
        vectorsSum = (vector1, vector2) ->
            result = []
            for x in [0..27]
                result[x] = vector1[x] + vector2[x]
            return result

        width = element.width()
        element.height(width / 2)

        today = ->
            moment().hour(0).minute(0)

        days = _.map([27..0], (x) ->
            today().subtract('days', x)
        )
        data = []
        for d in _.values(dataToDraw)
            if accumulated_data?
                accumulated_data = vectorsSum(accumulated_data, d.data)
            else
                accumulated_data = d.data

            data.unshift({
                label: d.name
                data: _.zip(days, accumulated_data)
                curvedLines:
                    apply: true
                    fit: true
            })
        options =
            grid:
                borderWidth: { top: 0, right: 1, left:0, bottom: 0 }
                borderColor: '#ccc'
            legend:
                position: "nw"
            xaxis:
                tickSize: [1, "day"]
                min: today().subtract('days', 27)
                max: today()
                mode: "time"
                daysNames: days
                axisLabel: 'Day'
                axisLabelUseCanvas: true
                axisLabelFontSizePixels: 12
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif'
                axisLabelPadding: 5
            yaxis:
                min: 0
            series:
                curvedLines:
                    active: true
                shadowSize: 0
                lines:
                    show: true
                    fill: true
                    fillColor: { colors: _.map(_.values(dataToDraw), (d) -> {'color':d.color}).reverse() }

            colors: _.map(_.values(dataToDraw), (d) -> d.color).reverse()


        element.empty()
        element.plot(data, options).data("plot")

    scope.$watch attrs.gmIssuesAccumulatedGraph, () ->
        value = scope.$eval(attrs.gmIssuesAccumulatedGraph)
        if value and scope.showGraphs
            redrawChart(_.values(value))
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesAccumulatedGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(_.values(value))
            , 200)

GmIssuesOpenClosedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        element.height(width / 2)

        today = ->
            moment().hour(0).minute(0)

        days = _.map([27..0], (x) ->
            today().subtract('days', x)
        )
        data = [
            {
                label: 'Open'
                data: _.zip(days, dataToDraw['open'])
                color: 'red'
                bars:
                    show: true
                    fill: true
                    lineWidth: 1
                    order: 1
                    barWidth: 24*60*60*300
                    fillColor:  "red"
            },
            {
                label: 'Closed'
                data: _.zip(days, dataToDraw['closed'])
                color: 'green'
                bars:
                    show: true
                    fill: true
                    lineWidth: 1
                    order: 2
                    barWidth: 24*60*60*300
                    fillColor:  "green"
            }
        ]
        options =
            grid:
                borderWidth: 0
            xaxis:
                tickSize: [1, "day"],
                min: today().subtract('days', 27),
                max: today(),
                mode: "time",
                daysNames: days,
                tickLength: 0
                axisLabel: 'Day',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            yaxis:
                axisLabel: 'Value',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            legend:
                labelBoxBorderColor: "none"
                position: "nw"

        element.empty()
        element.plot(data, options).data("plot")

    scope.$watch attrs.gmIssuesOpenClosedGraph, () ->
        value = scope.$eval(attrs.gmIssuesOpenClosedGraph)
        if value and scope.showGraphs
            redrawChart(value)
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesOpenClosedGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(value)
            , 200)

module = angular.module("taiga.directives.graphs", [])
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive("gmTaskboardGraph", GmTaskboardGraphDirective)
module.directive("gmIssuesPieGraph", GmIssuesPieGraphDirective)
module.directive("gmIssuesAccumulatedGraph", GmIssuesAccumulatedGraphDirective)
module.directive("gmIssuesOpenClosedGraph", GmIssuesOpenClosedGraphDirective)
