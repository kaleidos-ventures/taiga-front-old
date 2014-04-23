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


GmIssuesSortedByDirective = ($rootScope, $gmFilters) ->
    removeOrderingState = (element) ->
        candidates = element.parent().find(".icon-chevron-up, .icon-chevron-down")
        candidates.removeClass("icon-chevron-up")
        candidates.removeClass("icon-chevron-down")

    setStyle = (element, reverse=false) ->
        if reverse
            element.addClass("icon-chevron-up")
        else
            element.addClass("icon-chevron-down")

    getCurrentOrdering = ->
        ordering = $gmFilters.getOrdering($rootScope.projectId, "issues")

        if ordering is null
            result = {}
            result.orderBy = "status"
            result.isReverse = false
            return result

        if ordering.isReverse is undefined
            ordering.isReverse = false

        return ordering

    setCurrentOrdering = (ordering) ->
        $gmFilters.setOrdering($rootScope.projectId, "issues", ordering)

    link = (scope, element, attrs) ->
        field = attrs.gmIssuesSortedBy

        # Destructor
        element.on "$destroy", (event) ->
            element.off()

        # Event Handling
        element.on "click", (event) ->
            removeOrderingState(element)

            ordering = getCurrentOrdering()
            if ordering.orderBy == field
                ordering.isReverse = not ordering.isReverse
            else
                ordering.orderBy = field

            setCurrentOrdering(ordering)
            setStyle(element, ordering.isReverse)

            scope.$evalAsync(attrs.gmRefreshCallback)

        # Setting initial state
        initialize = _.once ->
            ordering = getCurrentOrdering()
            if ordering.orderBy == field
                setStyle(element, ordering.isReverse)

        scope.$watch "projectId", (v) ->
            initialize() if v != undefined

    return {link: link}


module = angular.module("taiga.directives.issues", ["taiga.services.filters"])
module.directive("gmIssuesSortedBy", ["$rootScope", "$gmFilters", GmIssuesSortedByDirective])
