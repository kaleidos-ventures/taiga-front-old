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


GmDoomlineDirective = ->
    priority: -20
    link: (scope, elm, attrs) ->
        removeDoomlineDom = ->
            elm.find(".doomline").remove()

        addDoomlienDom = (element) ->
            element?.before("<div class='doomline'></div>")

        generateDoomline = (elements) ->
            if not scope.projectStats?
                return false

            total_points = scope.projectStats.total_points
            current_sum = scope.projectStats.assigned_points
            added = false

            for element in elements
                scope = element.scope()

                if not scope.us?
                    continue

                current_sum += scope.us.total_points
                if current_sum > total_points and not added
                    addDoomlienDom(element)
                    added = true
                    break

            if current_sum <= total_points
                removeDoomlineDom()

        getUsItems = ->
            return _.map(elm.find(attrs.gmDoomlineElementSelector), (x) -> angular.element(x))

        reloadDoomlineLocation = ->
            removeDoomlineDom()
            generateDoomline(getUsItems())

        reloadDoomlineLocation()

        scope.$watch(attrs.gmDoomlineWatch, reloadDoomlineLocation)
        scope.$on("userstories:loaded", reloadDoomlineLocation)
        scope.$on("points:changed", reloadDoomlineLocation)
        scope.$on("project_stats:loaded", reloadDoomlineLocation)
        scope.$on("doomline:redraw", reloadDoomlineLocation)

module = angular.module("taiga.directives.backlog", [])
module.directive('gmDoomline', GmDoomlineDirective)
