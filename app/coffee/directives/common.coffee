GmHeaderMenuDirective = ($rootScope) ->
    return (scope, elm, attrs) ->
        element = angular.element(elm)
        menuSection = $rootScope.pageSection

        element.find(".selected").removeClass("selected")
        if menuSection is "backlog"
            element.find("li.backlog").addClass("selected")
        else if menuSection is "kanban"
            element.find("li.kanban").addClass("selected")
        else if menuSection is "issues"
            element.find("li.issues").addClass("selected")
        else if menuSection is "questions"
            element.find("li.questions").addClass("selected")
        else if menuSection is "wiki"
            element.find("li.wiki").addClass("selected")
        else if menuSection is "admin"
            element.find("li.admin").addClass("selected")


GmBreadcrumbDirective = ($rootScope) ->
    link: (scope, element, attrs) ->
        scope.$watch "pageBreadcrumb", (breadcrumb) ->
            if breadcrumb is undefined
                return

            total = breadcrumb.length-1
            element.empty()

            items = []
            for item, index in breadcrumb
                if item[1] == null
                    li = angular.element('<li data-icon="G" class="title-item"></li>').text(item[0])
                else
                    link = angular.element('<a></a>').text(item[0]).attr('href', item[1])
                    li = angular.element('<li data-icon="G" class="title-item"></li>').append(link)
                items.push(li)

            if not _.isEmpty(items)
                first = items[0]
                first.addClass('first-breadcrumb').removeAttr('data-icon')

            for item in items
                element.append(item)


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


GmNinjaGraphDirective = ->
    directive =
        restrict: "A"
        link: (scope, elm, attrs) ->
            element = angular.element(elm)
            graph = angular.element(".graph-box")

            element.on "click", (event) ->
                event.preventDefault()
                graph.slideToggle()

    return directive

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


GmColorizeTagDirective = -> (scope, elm, attrs) ->
    element = angular.element(elm)
    if _.isObject(scope.tag)
        hash = hex_sha1(scope.tag.name.toLowerCase())
    else
        hash = hex_sha1(scope.tag.toLowerCase())

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

    element.css('background-color', '#' + color)


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


GmPopoverDirective = ($parse, $compile) ->
    restrict: "A"
    link: (scope, element, attrs) ->
        fn = $parse(attrs.gmPopover)

        autoHide = element.data('auto-hide')
        placement = element.data('placement') or 'right'

        defaultAcceptSelector = '.popover-content .button-success, .popover-content .btn-accept'
        defaultCancelSelector = '.popover-content .button-delete'

        acceptSelector = element.data('accept-selector') or defaultAcceptSelector
        cancelSelector = element.data('cancel-selector') or defaultCancelSelector


        element.on "click", (event) ->
            event.preventDefault()

            template = _.str.trim($(element.data('tmpl')).html())
            template = angular.element($.parseHTML(template))

            scope.$apply ->
                template = $compile(template)(scope)


            element.popover({
                content: template,
                html:true,
                animation: false,
                delay: 0,
                trigger: "manual",
                placement: placement
            })

            element.popover("show")

            closeHandler = ->
                state = element.data('state')

                if state == "closing"
                    element.popover('destroy')
                    element.data('state', 'closed')


            next = element.next()
            next.on "click", acceptSelector, (event) ->
                event.preventDefault()

                target = angular.element(event.currentTarget)
                id = target.data('id')

                scope.$apply ->
                    fn(scope, {"selectedId": id})

                element.popover('destroy')
                next.off()

            next.on "click", cancelSelector, (event) ->
                element.popover('destroy')
                next.off()

            $('body').on "click", (event)->
                if not (element.has(event.target).length > 0 or element.is(event.target))
                    element.data('state', 'closing')
                    closeHandler()

            if autoHide
                element.data('state', 'closing')
                _.delay(closeHandler, 2000)

                next.on "mouseleave", ".popover-content", (event) ->
                    element.data('state', 'closing')
                    _.delay(closeHandler, 200)

                next.on "mouseenter", ".popover-content", (event) ->
                    element.data('state', 'open')


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


GmTagsInputDirective = ->
    restrict: "A"
    require: "ngModel"
    link: (scope, elm, attrs, ctrl) ->
        trimList = (list) ->
            return _.map(list, (i) -> i.trim())

        parser = (value) ->
            value = value.replace(/,\s/, ",")
            value = value.replace(/\./, ",")

            if _.isEmpty(value)
                return undefined

            value = trimList(value.split(","))
            return value

        formatter = (value) ->
            if value is undefined
                return value
            if _.isString(value)
                return value


            value = value.join(", ")
            return value

        ctrl.$parsers.push(parser)
        ctrl.$formatters.push(formatter)


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
    templateUrl: "partials/paginator.html"
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


GmSelectFix = ->
    require: 'ngModel',
    link: (scope, element, attrs, ngModel) ->
        ngModel.$parsers.push (value) ->
            if (value == null)
                value = ''
            return value

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


module = angular.module('taiga.directives.common', [])
module.directive('gmBreadcrumb', ["$rootScope", GmBreadcrumbDirective])
module.directive('gmHeaderMenu', ["$rootScope", GmHeaderMenuDirective])
module.directive('gmNinjaGraph', GmNinjaGraphDirective)
module.directive('gmColorizeTag', GmColorizeTagDirective)
module.directive('gmKalendae', GmKalendaeDirective)
module.directive('gmPopover', ['$parse', '$compile', GmPopoverDirective])
module.directive('gmForwardClick', GmForwardClickDirective)
module.directive('gmChecksleyForm', ['$parse', '$compile', '$window', GmChecksleyFormDirective])
module.directive('gmChecksleySubmitButton', [GmChecksleySubmitButtonDirective])
module.directive('gmTagsInput', [GmTagsInputDirective])
module.directive('gmSearchBox', ["$rootScope", "$location", SearchBoxDirective])
module.directive('gmRolePointsEdition', GmRolePointsEditionDirective)
module.directive('gmColorizeUser', ["$parse", GmColorizeUserDirective])
module.directive('gmPaginator', ['$parse', GmPaginator])
module.directive('gmSpinner', ['$parse', '$rootScope', GmSpinner])
module.directive('gmSelectFix', GmSelectFix)
module.directive('gmSortable', ["$log", "$rootScope", GmSortableDirective])
module.directive('gmEqualColumnWidth', GmEqualColumnWidth)
module.directive('gmKanbanSize', ["$window", GmKanbanSize])
