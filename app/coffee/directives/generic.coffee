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


GmFileDirective = ($parse) ->
    require: "?ngModel",
    restrict: "A",
    link: (scope, elm, attrs, ngModel) ->
        element = angular.element(elm)
        element.on 'change', (event) ->
            files = event.target.files
            if files.length == 1
                scope.$apply ->
                    ngModel.$setViewValue(files[0])


GmFilesDirective = ($parse) ->
    restrict: "A",
    link: (scope, elm, attrs) ->
        scope[attrs["gmFiles"]] = []
        element = angular.element(elm)
        element.on 'change', (event) ->
            files = _.map(event.target.files, (x)->x)
            if files.length >= 1
                scope.$apply ->
                    if scope[attrs["gmFiles"]].length == 0
                        scope[attrs["gmFiles"]] = files
                    else
                        scope[attrs["gmFiles"]] = scope[attrs["gmFiles"]].concat(files)



GmSelectedFiltersRendererDirective = ($compile) ->
    template = """
    <div class="tag selected" style="background: <%= tag.color %>">
        <div class="name"><%- tag.name %></div>
        <div class="count"><%- tag.count %></div>
    </div>
    """

    renderFilter = (item) ->
        tmpl = _.template(template)
        return tmpl({tag:item})

    renderFilters = (filters, scope, element) ->
        # Do nothing if no filters is found
        if filters is undefined
            return

        renderedItems = _.map(filters, renderFilter)
        html = angular.element.parseHTML(renderedItems.join("\n"))

        element.html(html)
        $compile(element.contents())(scope)

    return (scope, element, attrs) ->
        currentFilters = []

        scope.$watch attrs.gmSelectedFiltersRenderer, (filters) ->
            currentFilters = filters
            renderFilters(filters, scope, element)

        element.on "click", ".tag", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)
            filter = currentFilters[target.index()]

            # filters = _.clone(currentFilters, false)
            # filters.splice(target.index(), 1)
            # renderFilters(filters, scope, element)

            if filter
                scope.$apply ->
                    scope.$eval(attrs.gmToggleFilterCallback, {tag:filter})

        element.on "$destroy", (event) ->
            element.off()


module = angular.module('taiga.directives.generic', [])
module.directive('gmFile', ["$parse", GmFileDirective])
module.directive('gmFiles', ["$parse", GmFilesDirective])
module.directive("gmSelectedFiltersRenderer", ["$compile", GmSelectedFiltersRendererDirective])
