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
            elm.find(".doomline").remove()

        addDoomlienDom = (element) ->
            dom = angular.element("<div/>", {"class": "doomline"})
            dom.css("border-bottom", "1px solid red")
            dom.css("height", "1px")
            dom.insertAfter(element)

        generateDoomline = (elements) ->
            total_points = scope.project.total_story_points
            current_sum = 0
            added = false

            for element in elements
                scope = element.scope()
                current_sum += scope.us.total_points

                if current_sum >= total_points and not added
                    addDoomlienDom(element)
                    added = true

            if current_sum <= total_points
                removeDoomlineDom()

        getUsItems = ->
            return _.map(elm.find("div.us-item"), (x) -> angular.element(x))

        scope.$on "userstories:loaded", ->
            removeDoomlineDom()
            gm.utils.delay 500, ->
                generateDoomline(getUsItems())

        scope.$on "sortable:changed", ->
            removeDoomlineDom()
            gm.utils.delay 500, ->
                generateDoomline(getUsItems())


module = angular.module("greenmine.directives.backlog", [])
module.directive('gmDoomline', GmDoomlineDirective)
