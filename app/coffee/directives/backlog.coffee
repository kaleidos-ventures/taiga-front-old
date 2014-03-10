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
                if scope.us
                    current_sum += scope.us.total_points

                if current_sum > total_points and not added
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
        scope.$on("points:changed", reloadDoomlineLocation)
        scope.$on("project_stats:loaded", reloadDoomlineLocation)

module = angular.module("taiga.directives.backlog", [])
module.directive('gmDoomline', GmDoomlineDirective)
