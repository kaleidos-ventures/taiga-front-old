# Copyright 2013 Andrey Antukh <niwi@niwi.be>
#
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
        getOptimalList = (totalPoints, numOfSprints) ->
            (totalPoints-((totalPoints/(numOfSprints))*sprintNum) for sprintNum in [0..numOfSprints])

        getLabels = (listOfMilestones, numOfSprints) ->
            result = []
            if listOfMilestones.length > numOfSprints
                result = _.map(listOfMilestones, 'name')
            else
                difference = numOfSprints - listOfMilestones.length
                counter = 0
                for x in [0..numOfSprints-1]
                    if listOfMilestones.length > x
                        result.push listOfMilestones[x].name
                    else
                        counter++
                        result.push "Future sprint #{counter}"
            result.push ""
            return result

        getEvolutionPoints = (listOfMilestones, totalPoints) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = [totalPoints]
            _.each(listOfMilestones, (milestone, index) ->
                if isNaN(result[index] - milestone.closed_points["1"])
                    result.push(0)
                else
                    result.push(result[index] - milestone.closed_points["1"])
            )
            return result

        getTeamIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = [0]
            _.each(listOfMilestones, (milestone, index) ->
                if isNaN(result[index] - milestone.team_increment_points["1"])
                    result.push(0)
                else
                    result.push(result[index] - milestone.team_increment_points["1"])
            )
            return result

        getClientIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = getTeamIncrementPoints(listOfMilestones)
            _.each(listOfMilestones, (milestone, index) ->
                if isNaN(result[index] - milestone.client_increment_points["1"])
                    result.push(0)
                else
                    result[index+1] += (result[index] - milestone.client_increment_points["1"])
            )
            return result

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
            labels : getLabels(scope.project.list_of_milestones, scope.project.total_milestones)
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : getOptimalList(scope.project.total_story_points, scope.project.total_milestones)
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : getEvolutionPoints(scope.project.list_of_milestones, scope.project.total_story_points)
                },
                {
                    fillColor : "rgba(153,51,51,0.3)",
                    strokeColor : "rgba(153,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : getTeamIncrementPoints(scope.project.list_of_milestones)
                },
                {
                    fillColor : "rgba(255,51,51,0.3)",
                    strokeColor : "rgba(255,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : getClientIncrementPoints(scope.project.list_of_milestones)
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'project', (value) ->
        if scope.project
            redrawChart()


GmDoomlineDirective = ->
    priority: -20
    link: (scope, elm, attrs) ->
        removeDoomlineDom = ->
            elm.find(".doomline").removeClass("doomline")

        addDoomlienDom = (element) ->
            element.addClass("doomline")

        generateDoomline = (elements) ->
            total_points = scope.project.total_story_points
            current_sum = 0
            added = false

            for element in elements
                scope = element.scope()
                current_sum += scope.us.total_points

                if current_sum == total_points and not added
                    addDoomlienDom(element)
                    added = true
                else if current_sum > total_points and not added
                    addDoomlienDom(element.prev())
                    added = true

            if current_sum <= total_points
                removeDoomlineDom()

        getUsItems = ->
            return _.map(elm.find("div.us-item"), (x) -> angular.element(x))

        reloadDoomlineLocation = ->
            removeDoomlineDom()
            gm.utils.delay 500, ->
                generateDoomline(getUsItems())

        scope.$on("userstories:loaded", reloadDoomlineLocation)
        scope.$on("sortable:changed", reloadDoomlineLocation)
        scope.$on("points:changed", reloadDoomlineLocation)


GmSortableDirective = ($log) ->
    require: '?ngModel'
    link: (scope, element, attrs, ngModel) ->
        opts = {connectWith: attrs.gmSortable}

        if ngModel
            ngModel.$render = ->
                $log.info "GmSortableDirective.$render"
                element.sortable( "refresh" )

            onStart = (e, ui) ->
                $log.info "GmSortableDirective.onStart", ui.item.index()
                ui.item.sortable = { index: ui.item.index() }

            onUpdate = (e, ui) ->
                $log.info "GmSortableDirective.onUpdate"
                ui.item.sortable.model = ngModel
                ui.item.sortable.scope = scope

            onReceive = (e, ui) ->
                $log.info "GmSortableDirective.onReceive"
                ui.item.sortable.relocate = true

            onRemove = (e, ui) ->
                $log.info "GmSortableDirective.onRemove"
                if ngModel.$modelValue.length == 1
                    ui.item.sortable.moved = ngModel.$modelValue.splice(0, 1)[0]
                else
                    ui.item.sortable.moved =  ngModel.$modelValue.splice(ui.item.sortable.index, 1)[0]

            onStop = (e, ui) ->
                $log.info "GmSortableDirective.onStop"
                if ui.item.sortable.model and not ui.item.sortable.relocate
                    # Fetch saved and current position of dropped element
                    start = ui.item.sortable.index
                    end = ui.item.index()

                    # Reorder array and apply change to scope
                    ui.item.sortable.model.$modelValue.splice(end-1, 0, ui.item.sortable.model.$modelValue.splice(start-1, 1)[0])
                    scope.$emit("sortable:changed")
                else
                    ui.item.sortable.moved.order = ui.item.index()
                    ui.item.sortable.model.$modelValue.splice(ui.item.index(), 0, ui.item.sortable.moved)

                    ui.item.sortable.scope.$emit("sortable:changed")
                    scope.$emit("sortable:changed")

                scope.$apply()

            opts.start = onStart
            opts.stop = onStop
            opts.receive = onReceive
            opts.remove = onRemove
            opts.update = onUpdate

        # Create sortable
        element.sortable(opts)


module = angular.module("greenmine.directives.backlog", [])
module.directive('gmDoomline', GmDoomlineDirective)
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive('gmSortable', ["$log", GmSortableDirective])
