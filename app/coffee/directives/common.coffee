commonModule = angular.module('greenmine.directives.common', [])

gmBacklogGraphConstructor = ($parse) ->
    return (scope, elm, attrs) ->

        element = angular.element(elm)

        width = element.width()
        height = width/6

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "burndown-chart")
        element.append(chart)

        ctx = $("#burndown-chart").get(0).getContext("2d")

        options =
            animation: false,
            bezierCurve: false,
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = {
            labels : ["January","February","March","April","May","June"],
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : [100, 80, 60, 40, 20, 0]
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : [100,92,68,45,19,0]
                }
            ]
        }

        new Chart(ctx).Line(data, options)

commonModule.directive("gmBacklogGraph", gmBacklogGraphConstructor)


headerMenuConstructor = ($rootScope) ->
    return (scope, elm, attrs) ->
        element = angular.element(elm)
        menuSection = $rootScope.pageSection

        element.find(".selected").removeClass("selected")
        if menuSection is "backlog"
            element.find("li.backlog").addClass("selected")
            element.find("li.dashboard").show()
        else if menuSection is "dashboard"
            element.find("li.dashboard").addClass("selected")
            element.find("li.dashboard").show()
        else if menuSection is "issues"
            element.find("li.issues").addClass("selected")
        else if menuSection is "questions"
            element.find("li.questions").addClass("selected")
        else if menuSection is "wiki"
            element.find("li.wiki").addClass("selected")
        else
            element.hide()

commonModule.directive('gmHeaderMenu', ["$rootScope", headerMenuConstructor])


breadcrumbsConstructor = ($rootScope) ->
    return (scope, elm, attrs) ->
        breadcrumb = $rootScope.pageBreadcrumb

        if breadcrumb is undefined
            return

        element = angular.element(elm)
        total = breadcrumb.length-1

        element.empty()
        _.each breadcrumb, (item, index) ->
            element.append(angular.element('<span class="title-item"></span>').text(item))
            if index != total
                element.append(angular.element('<span class="separator"> &rsaquo; </span>'))

commonModule.directive('gmBreadcrumb', ["$rootScope", breadcrumbsConstructor])

commonModule.
    directive('gmNinjaGraph', ->
        return {
            restrict: "A",
            link: (scope, elm, attrs) ->
                element = angular.element(elm)
                graph = angular.element(".graph-box")

                element.on "click", (event) ->
                    event.preventDefault()
                    graph.fadeToggle()
        }
    ).
    directive('gmColorizeTag', ->
        return (scope, elm, attrs) ->
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
    ).
    directive("gmKalendae", ->
        return {
            require: "?ngModel"
            link: (scope, elm, attrs, ngModel) ->
                element = angular.element(elm)
                options =
                    format: "YYYY-MM-DD"

                kalendae = new Kalendae.Input(element.get(0), options)
                element.data('kalendae', kalendae)

                kalendae.subscribe 'change', (date, action) ->
                    self = this
                    scope.$apply ->
                        ngModel.$setViewValue(self.getSelected())
        }
    ).
    directive("uiSortable", ->
        uiConfig = {}

        return {
            require: '?ngModel',
            link: (scope, element, attrs, ngModel) ->
                opts = angular.extend({}, uiConfig.sortable)
                opts.connectWith = attrs.uiSortable

                if ngModel
                    ngModel.$render = ->
                        element.sortable( "refresh" )

                    onStart = (e, ui) ->
                        # Save position of dragged item
                        ui.item.sortable = { index: ui.item.index() }
                        # console.log("onStart", ui.item.index())

                    onUpdate = (e, ui) ->
                        # For some reason the reference to ngModel in stop() is wrong
                        # console.log("onUpdate", ngModel.$modelValue)
                        ui.item.sortable.model = ngModel
                        ui.item.sortable.scope = scope

                    onReceive = (e, ui) ->
                        # console.log("onReceive", ui.item.sortable.moved)

                        ui.item.sortable.relocate = true
                        # ngModel.$modelValue.splice(ui.item.index(), 0, ui.item.sortable.moved)
                        # ngModel.$viewValue.splice(ui.item.index(), 0, ui.item.sortable.moved)

                        # scope.$digest()
                        # scope.$broadcast("backlog-resort")

                    onRemove = (e, ui) ->
                        if ngModel.$modelValue.length == 1
                            ui.item.sortable.moved = ngModel.$modelValue.splice(0, 1)[0]
                        else
                            ui.item.sortable.moved =  ngModel.$modelValue.splice(ui.item.sortable.index, 1)[0]

                    onStop = (e, ui) ->
                        if ui.item.sortable.model and not ui.item.sortable.relocate
                            # Fetch saved and current position of dropped element
                            start = ui.item.sortable.index
                            end = ui.item.index()

                            # Reorder array and apply change to scope
                            ui.item.sortable.model.$modelValue.splice(end, 0, ui.item.sortable.model.$modelValue.splice(start, 1)[0])
                            # scope.$broadcast("sortable:changed")
                            scope.$emit("sortable:changed")
                        else
                            scope.$apply ->
                                ui.item.sortable.moved.order = ui.item.index()
                                ui.item.sortable.model.$modelValue.splice(ui.item.index(), 0, ui.item.sortable.moved)

                            scope.$apply ->
                                # ui.item.sortable.scope.$broadcast("sortable:changed")
                                ui.item.sortable.scope.$emit("sortable:changed")
                                scope.$emit("sortable:changed")

                        scope.$apply()

                    # If user provided 'start' callback compose it with onStart
                    opts.start = ((_start) ->
                        return (e, ui) ->
                            onStart(e, ui)
                            if typeof _start == ""
                                _start(e, ui)
                    )(opts.start)

                    # If user provided 'start' callback compose it with onStart
                    opts.stop = ((_stop) ->
                        return (e, ui) ->
                            onStop(e, ui)
                            if typeof _stop == ""
                                _stop(e, ui)
                    )(opts.stop)

                    # If user provided 'update' callback compose it with onUpdate
                    opts.update = ((_update) ->
                        return (e, ui) ->
                            onUpdate(e, ui)
                            if typeof _update == ""
                                _update(e, ui)
                    )(opts.update)

                    # If user provided 'receive' callback compose it with onReceive
                    opts.receive = ((_receive) ->
                        return (e, ui) ->
                            onReceive(e, ui)
                            if typeof _receive == ""
                                _receive(e, ui)
                    )(opts.receive)

                    # If user provided 'remove' callback compose it with onRemove
                    opts.remove = ((_remove) ->
                        return (e, ui) ->
                            onRemove(e, ui)
                            if typeof _remove == ""
                                _remove(e, ui)
                    )(opts.remove)

                # Create sortable
                element.sortable(opts)
        }
    ).
    directive('gmPopover', ['$parse', '$compile', ($parse, $compile) ->
        createContext = (scope, element) ->
            context = (element.data('ctx') or "").split(",")
            data = {_scope: scope}

            _.each context, (key) ->
                key = _.str.trim(key)
                data[key] = scope[key]

            return data

        return {
            restrict: "A",
            link: (scope, elm, attrs) ->
                fn = $parse(attrs.gmPopover)
                element = angular.element(elm)

                autoHide = element.data('auto-hide')
                placement = element.data('placement') or 'right'

                closeHandler = ->
                    state = element.data('state')

                    if state == "closing"
                        element.popover('hide')
                        element.data('state', 'closed')

                element.on "click", (event) ->
                    event.preventDefault()
                    context = createContext(scope, element)
                    template = _.str.trim($(element.data('tmpl')).html())
                    template = angular.element($.parseHTML(template))

                    scope.$apply ->
                        $compile(template)(scope)

                    element.popover(
                        content: template,
                        html:true,
                        animation: false,
                        delay: 0,
                        trigger: "manual",
                        placement: placement
                    )

                    element.popover("show")

                    if autoHide is not undefined
                        element.data('state', 'closing')
                        _.delay(closeHandler, 2000)

                parentElement = element.parent()
                acceptSelector = element.data('accept-selector') or '.popover-content .button-success, .popover-content .btn-accept'
                cancelSelector = element.data('cancel-selector') or '.popover-content .button-delete'

                parentElement.on "click", acceptSelector, (event) ->
                    event.preventDefault()

                    context = createContext(scope, element)
                    target = angular.element(event.currentTarget)
                    id = target.data('id')

                    context = _.extend(context, {"selectedId": id})

                    scope.$apply ->
                        fn(scope, context)

                    element.popover('hide')

                parentElement.on "click", cancelSelector, (event) ->
                    element.popover('hide')

                if autoHide
                    parentElement.on "mouseleave", ".popover", (event) ->
                        target = angular.element(event.currentTarget)
                        element.data('state', 'closing')
                        _.delay(closeHandler, 200)

                    parentElement.on "mouseenter", ".popover", (event) ->
                        target = angular.element(event.currentTarget)
                        element.data('state', 'open')
        }
    ]).
    directive('gmFlashMessage', ->
        return (scope, elm, attrs) ->
            element = angular.element(elm)
            scope.$on "flash:new", (ctx, success, message) ->
                if success
                    element.find(".flash-message-success p").text(message)
                    element.find(".flash-message-success").fadeIn().delay(2000).fadeOut()
                else
                    element.find(".flash-message-fail p").text(message)
                    element.find(".flash-message-fail").fadeIn().delay(2000).fadeOut()
    ).
    directive("gmModal", ["$parse", "$compile", ($parse, $compile) ->
        return {
            restrict: "A",
            link: (scope, elm, attrs) ->
                element = angular.element(elm)
                body = angular.element("body")
                modal = null

                initCallback = $parse(element.data('init'))
                cancelCallback = $parse(element.data('end-cancel'))

                element.on "click", (event) ->
                    if modal is not undefined
                        scope.$apply ->
                            modal.modal('hide')
                            initCallback(scope)
                            modal.modal("show")

                    else
                        modaltTmpl = _.str.trim(angular.element(attrs.gmModal).html())

                        modal = angular.element($.parseHTML(modaltTmpl))
                        modal.attr("id", _.uniqueId("modal-"))
                        modal.on "click", ".button-cancel", (event) ->
                            event.preventDefault()
                            scope.$apply ->
                                cancelCallback(scope)

                            modal.modal('hide')

                        body.append(modal)
                        scope.$apply ->
                            initCallback(scope)
                            $compile(modal.contents())(scope)
                        modal.modal()

                scope.$on 'modals:close', ->
                    if modal is not undefined
                        modal.modal('hide')
        }
    ])
