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

GmDoomlineDirective = ->
    priority: -20
    link: (scope, elm, attrs) ->
        removeDoomlineDom = ->
            elm.find(".doomline").removeClass("doomline")

        addDoomlienDom = (element) ->
            element.addClass("doomline")

        generateDoomline = (elements) ->
            if not scope.projectStats?
                return false

            total_points = scope.projectStats.total_points
            current_sum = scope.projectStats.assigned_points
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
        scope.$on("project_stats:loaded", reloadDoomlineLocation)


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
                    ui.item.sortable.model.$modelValue.splice(end, 0, ui.item.sortable.model.$modelValue.splice(start, 1)[0])
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
module.directive('gmSortable', ["$log", GmSortableDirective])
