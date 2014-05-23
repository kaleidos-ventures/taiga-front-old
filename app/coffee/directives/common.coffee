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


GmHeaderMenuDirective = ($rootScope) ->
    return (scope, elm, attrs) ->
        element = angular.element(elm)
        menuSection = scope.$eval(attrs.gmHeaderMenu)

        element.find(".selected").removeClass("selected")
        element.find(".#{menuSection}").addClass("selected")


GmBreadcrumbDirective = ->
    link: (scope, element, attrs) ->
        drawBreadcrumb = (breadcrumb) =>
            if not breadcrumb?
                return null

            element.empty()

            items = []
            for item, index in breadcrumb
                li = angular.element('<li data-icon="G" class="title-item"></li>')
                if (typeof item) == "string"
                    li.text(item)
                else if item[1]?
                    link = angular.element('<a></a>').text(item[0]).attr('href', item[1])
                    li.append(link)
                else
                    li.text(item[0])
                items.push(li)

            items[0]?.addClass('first-breadcrumb').removeAttr('data-icon')

            for item in items
                element.append(item)

        scope.$watch attrs.gmBreadcrumb, (breadcrumb) ->
            drawBreadcrumb(breadcrumb)

        drawBreadcrumb(scope.$eval(attrs.gmBreadcrumb))


SearchBoxDirective = ($rootScope, $location) ->
    link: (scope, elm, attrs) ->
        form = elm.find("form")
        form.on "submit", (event) ->
            event.preventDefault()

            action = form.attr('action')
            value = form.find("input").val()

            scope.$apply ->
                path = $rootScope.urls.searchUrl(scope.projectSlug, true)
                $location.path(path).search({term: value})


CoffeeColorPickerDirective = ->
    directive =
        restrict: "A"
        link: (scope, elm, attrs) ->
            element = angular.element(elm)
            element.coffeeColorPicker()
            element.on 'pick', (event, color) ->
                scope.$color = color
                scope.$apply () ->
                    scope.$eval(attrs.gmColorPicker)

    return directive


GmColorizeTagDirective = ($parse) ->
    restrict: "A"
    link: (scope, elm, attrs) ->
        updateColor = ->
            tag = $parse(attrs.gmColorizeTag)(scope)

            if tag
                if _.isObject(tag)
                    hash = hex_sha1(tag.name.toLowerCase())
                else
                    hash = hex_sha1(tag.toLowerCase())

                color = hash
                    .substring(0,6)
                    .replace('8','0')
                    .replace('9','1')
                    .replace('a','2')
                    .replace('b','3')
                    .replace('c','4')
                    .replace('d','5')
                    .replace('e','6')
                    .replace('f','7')

                element = angular.element(elm)
                element.css('background-color', '#' + color)

        scope.$watch attrs.gmColorizeTag, () ->
            updateColor()


GmKalendaeDirective = ->
    directive =
        require: "?ngModel"
        link: (scope, elm, attrs, ctrl) ->
            element = angular.element(elm)
            kalendae = new Kalendae.Input(element.get(0), {format:"YYYY-MM-DD"})
            kalendae.subscribe 'change', (date, action) ->
                ctrl.$setViewValue(@.getSelected())
                scope.$apply()

    return directive


GmForwardClickDirective = ->
    restrict: "A"
    link: (scope, element, attrs) ->
        selector = attrs.gmForwardClick

        element.on "click", (event) ->
            event.preventDefault()
            angular.element(attrs.gmForwardClick).trigger("click")


GmChecksleyFormDirective = ($parse, $compile, $window) ->
    restrict: "A"
    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        element.on "submit", (event) ->
            event.preventDefault()

        callback = $parse(attrs.gmChecksleyForm)
        onFormSubmit = (ok, event, form) ->
            scope.$apply ->
                callback(scope) if ok

        form = element.checksley(listeners: {onFormSubmit: onFormSubmit})

        attachChecksley = ->
            form.destroy()
            form.initialize()

        scope.$on("$includeContentLoaded", attachChecksley)
        scope.$on("checksley:reset", attachChecksley)

        scope.$watch "checksleyErrors", (errors) ->
            if not _.isEmpty(errors)
                form.setErrors(errors)


GmChecksleySubmitButtonDirective = ->
    restrict: "A"
    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        element.on "click", (event) ->
            event.preventDefault()
            element.closest("form").trigger("submit")


GmRolePointsEditionDirective = ->
    compile: (element, attrs) ->
        template = """
        <fieldset class="us-role-points" ng-repeat="role in constants.computableRolesList">
            {{ role.name }} (points)

            <select class="points" name="points" ng-model="form.points[role.id]" data-required="true"
                data-error-message="Required" ng-options="c.id as c.name for c in constants.pointsList|orderBy:'order'">
            </select>
        </fieldset>"""

        element.html(template)
        return @.link

    link: (scope, elm, attrs) ->
        if scope.form is undefined
            scope.form = {}

        if scope.form.points is undefined
            scope.form.points = {}


GmColorizeUserDirective = ($parse)->
    restrict: "A"
    link: (scope, elm, attrs) ->
        updateColor = ->
            element = angular.element(elm)
            user = $parse(attrs.gmColorizeUser)(scope)
            if user and user.color
                element.css({
                    "padding": "0 5px"
                    "border-left-width": "15px"
                    "border-left-style": "solid"
                    "border-left-color": user.color
                })
            else
                element.css({
                    "padding": "0 0"
                    "border-left-width": "0px"
                })

        scope.$watch attrs.gmColorizeUser, () ->
            updateColor()

GmSpinner = ($parse, $rootScope) ->
    restrict: "A"
    link: (scope, element, attrs) ->
        el = angular.element("<div/>", {"class": "spinner"})
        el.hide()
        element.append(el)

        $rootScope.$on "spinner:start", ->
            el.show()

        $rootScope.$on "spinner:stop", ->
            el.hide()


GmPaginator = ($parse) ->
    # Also, it assume that scope contains a:
    #  - count variable
    #  - setPage(page) function

    restrict: "A"
    require: "?ngModel"
    templateUrl: "/partials/paginator.html"
    link: (scope, elm, attrs, ctrl) ->
        element = angular.element(elm)
        element.hide()

        scope.paginatorHidden = true

        setPageVar = element.data('set-page-var') or 'setPage'
        pageVar = element.data('page-var') or 'page'
        countVar = element.data('count-var') or 'count'
        after_current = element.data('after-current') or 5
        before_current = element.data('before-current') or 5
        at_begin = element.data('at-begin') or 2
        at_end = element.data('at-end') or 2

        scope.paginatorSetPage = (page) ->
            numPages = getNumPages()
            if page <= numPages and page > 0
                scope[setPageVar](page)

        scope.paginatorGetPage = () ->
            return scope[pageVar]

        getNumPages = ->
            numPages = scope[countVar] / scope.paginatedBy
            if parseInt(numPages, 10) < numPages
                numPages = parseInt(numPages, 10) + 1
            else
                numPages = parseInt(numPages, 10)

            return numPages

        renderPaginator = ->
            if scope[countVar] is undefined
                return

            numPages = getNumPages()

            scope.paginationItems = []
            scope.paginatorHidden = false

            if scope[pageVar] > 1
                scope.showPrevious = true
            else
                scope.showPrevious = false

            if scope[pageVar] == numPages
                scope.showNext = false
            else
                scope.showNext = true

            if numPages <= 1
                element.hide()
            else
                for i in [1..numPages]
                    if i == (scope[pageVar] + after_current) and numPages > (scope[pageVar] + after_current + at_end)
                        scope.paginationItems.push(classes:"dots", type:"dots")
                    else if i == (scope[pageVar] - before_current) and scope[pageVar] > (at_begin + before_current)
                        scope.paginationItems.push(classes:"dots", type:"dots")
                    else if i > (scope[pageVar] + after_current) and i <= (numPages - at_end)
                        true # ignore
                    else if i < (scope[pageVar] - before_current) and i > at_begin
                        true # ignore
                    else if i == scope[pageVar]
                        scope.paginationItems.push(classes:"page active", num:i, type:"page-active")
                    else
                        scope.paginationItems.push(classes:"page", num:i, type:"page")

                element.show()

            scope.$apply()

        scope.$watch countVar, (value) ->
            _.defer(renderPaginator)

        scope.$watch pageVar, (value) ->
            _.defer(renderPaginator)


GmEqualColumnWidth = ->
    link: (scope, element, attrs) ->
        scope.$watch attrs.watch, ->
            tds = element.find('thead tr td')
            if tds.length == 0
                return
            minWidth = attrs.minWidth or 0
            optimalWidth = $(element).width() / tds.length
            if optimalWidth < minWidth
                width = minWidth
            else
                width = optimalWidth

            $(tds).attr('width', "#{width}px")

GmKanbanSize = ($window) ->
    link: (scope, element, attrs) ->
        setElementWidth = ->
            optimalWidth = $($window).width() - 20
            element.css('width', "#{optimalWidth}px")

        setColumnsWidth = ->
            tds = element.find('thead tr td')
            if tds.length == 0
                return
            minWidth = attrs.minWidth or 0
            optimalWidth = $(element).width() / tds.length
            if optimalWidth < minWidth
                width = minWidth
            else
                width = optimalWidth

            element.find('table thead tr td').attr('width', "#{width}px")
            element.find('table tbody tr td').attr('width', "#{width}px")

        setElementHeight = ->
            headerHeight = $('.header-container').height()
            filtersHeight = $('.filters-container').height()
            optimalHeight = $($window).height() - headerHeight - filtersHeight - 10
            element.css('height', "#{optimalHeight}px")

        scope.$watch attrs.watch, ->
            setElementHeight()
            setElementWidth()
            setColumnsWidth()

        scope.$watch "filtersOpened", ->
            setElementHeight()
            setElementWidth()
            setColumnsWidth()

        scope.$on "kanban:redraw", ->
            setElementHeight()
            setElementWidth()
            setColumnsWidth()

        $($window).resize ->
            setElementHeight()
            setElementWidth()
            setColumnsWidth()

GmSortableDirective = ($log, $rootScope) ->
    scope: true
    link: (scope, element, attrs) ->
        onAdd = scope.$eval(attrs.gmSortableOnAdd) or angular.noop
        onRemove = scope.$eval(attrs.gmSortableOnRemove) or angular.noop
        onUpdate = scope.$eval(attrs.gmSortableOnUpdate) or angular.noop
        itemName = attrs.gmSortableItemName or "item"
        selector = attrs.gmSortableSelector

        new Sortable element[0], {
            group: attrs.gmSortable
            draggable: selector

            onUpdate: (event) ->
                $log.debug "GmSortableDirective.onUpdate"
                orderedItems = _.sortBy element.find(selector), (item) -> angular.element(item).index()
                items = _.map orderedItems, (item) -> angular.element(item).scope()[itemName]
                onUpdate(items, scope)

            onAdd: (event) ->
                $log.debug "GmSortableDirective.onAdd"
                item = angular.element(event.item)
                onAdd(item.scope()[itemName], item.index(), scope)
                item.remove()

            onRemove: (event) ->
                $log.debug "GmSortableDirective.onRemove"
                item = angular.element(event.item)
                onRemove(item.scope()[itemName], scope)
        }

GmKanbanWip = ->
    link: (scope, elm, attrs) ->
        removeWiplineDom = ->
            elm.find(".wipline").remove()

        addWiplineDom = (element) ->
            element?.after("<div class='wipline'></div>")

        generateWipline = (elements) ->
            wip = scope.$eval(attrs.gmKanbanWip)
            if (elements.length > wip)
                addWiplineDom(elements[wip - 1])

        getUsItems = ->
            return _.map(elm.find(attrs.gmKanbanWipElementSelector), (x) -> angular.element(x))

        reloadWiplineLocation = ->
            removeWiplineDom()
            generateWipline(getUsItems())

        reloadWiplineLocation()

        scope.$watch attrs.gmKanbanWipWatch, ->
            reloadWiplineLocation()

        scope.$on "wipline:redraw", ->
            reloadWiplineLocation()


module = angular.module('taiga.directives.common', [])
module.directive('gmBreadcrumb', GmBreadcrumbDirective)
module.directive('gmHeaderMenu', ["$rootScope", GmHeaderMenuDirective])
module.directive('gmColorizeTag', ["$parse", GmColorizeTagDirective])
module.directive('gmKalendae', GmKalendaeDirective)
module.directive('gmForwardClick', GmForwardClickDirective)
module.directive('gmChecksleyForm', ['$parse', '$compile', '$window', GmChecksleyFormDirective])
module.directive('gmChecksleySubmitButton', [GmChecksleySubmitButtonDirective])
module.directive('gmSearchBox', ["$rootScope", "$location", SearchBoxDirective])
module.directive('gmRolePointsEdition', GmRolePointsEditionDirective)
module.directive('gmColorizeUser', ["$parse", GmColorizeUserDirective])
module.directive('gmPaginator', ['$parse', GmPaginator])
module.directive('gmSpinner', ['$parse', '$rootScope', GmSpinner])
module.directive('gmSortable', ["$log", "$rootScope", GmSortableDirective])
module.directive('gmEqualColumnWidth', GmEqualColumnWidth)
module.directive('gmKanbanSize', ["$window", GmKanbanSize])
module.directive('gmKanbanWip', GmKanbanWip)
