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
                result.push(result[index] - milestone.closed_points)
            )
            result

        getTeamIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = [0]
            _.each(listOfMilestones, (milestone, index) ->
                result.push(result[index] - milestone.team_increment_points)
            )
            result

        getClientIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = getTeamIncrementPoints(listOfMilestones)
            _.each(listOfMilestones, (milestone, index) ->
                result[index+1] += (result[index] - milestone.client_increment_points)
            )
            result

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
            labels : getLabels(scope.project.list_of_milestones, scope.project.sprints)
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : getOptimalList(scope.project.total_story_points, scope.project.sprints)
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



GmHeaderMenuDirective = ($rootScope) ->
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


GmBreadcrumbDirective = ($rootScope) ->
    return (scope, element, attrs) ->

        scope.$watch "pageBreadcrumb", (breadcrumb) ->
            if breadcrumb is undefined
                return

            total = breadcrumb.length-1
            element.empty()

            items = []

            for item, index in breadcrumb
                items.push(angular.element('<span class="title-item"></span>').text(item))

                if index != total
                    items.push(angular.element('<span class="separator"> &rsaquo; </span>'))

            if not _.isEmpty(items)
                first = items[0]
                first.css('font-weight', 'bold')
                first.css('color', 'black')
                first.css('curso', 'pointer')

            for item in items
                element.append(item)

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


GmSortableDirective = ->
    uiConfig = {}

    directive =
        require: '?ngModel'
        link: (scope, element, attrs, ngModel) ->
            opts = angular.extend({}, uiConfig.sortable)
            opts.connectWith = attrs.gmSortable

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
    return directive

GmPopoverDirective = ($parse, $compile) ->
    createContext = (scope, element) ->
        context = (element.data('ctx') or "").split(",")
        data = {_scope: scope}

        _.each context, (key) ->
            key = _.str.trim(key)
            data[key] = scope[key]

        return data

    directive =
        restrict: "A"
        link: (scope, element, attrs) ->
            fn = $parse(attrs.gmPopover)

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

                element.popover({
                    content: template,
                    html:true,
                    animation: false,
                    delay: 0,
                    trigger: "manual",
                    placement: placement
                })

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
                    element.data('state', 'closing')
                    _.delay(closeHandler, 200)

                parentElement.on "mouseenter", ".popover", (event) ->
                    element.data('state', 'open')

    return directive

GmFlashMessageDirective = -> (scope, elm, attrs) ->
    element = angular.element(elm)
    scope.$on "flash:new", (ctx, success, message) ->
        if success
            element.find(".flash-message-success p").text(message)
            element.find(".flash-message-success").fadeIn().delay(2000).fadeOut()
        else
            element.find(".flash-message-fail p").text(message)
            element.find(".flash-message-fail").fadeIn().delay(2000).fadeOut()


GmModalDirective = ($parse, $compile) ->
    directive =
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
                        $compile(modal)(scope)
                    modal.modal()

            scope.$on 'modals:close', ->
                if modal is not undefined
                    modal.modal('hide')

    return directive



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

        attachChecksley = ->
            element.checksley('destroy')
            element.checksley(listeners: {onFormSubmit: onFormSubmit})

        scope.$on("$includeContentLoaded", attachChecksley)
        scope.$on("checksley:reset", attachChecksley)
        element.checksley(listeners: {onFormSubmit: onFormSubmit})


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
            console.log "parser", value
            return value

        formatter = (value) ->
            if value is undefined
                return value
            if _.isString(value)
                return value


            value = value.join(", ")
            console.log "formatter", value
            return value

        ctrl.$parsers.push(parser)
        ctrl.$formatters.push(formatter)



module = angular.module('greenmine.directives.common', [])
module.directive('gmBreadcrumb', ["$rootScope", GmBreadcrumbDirective])
#Commented because blocks totally the browser.
#module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive('gmHeaderMenu', ["$rootScope", GmHeaderMenuDirective])
module.directive('gmNinjaGraph', GmNinjaGraphDirective)
module.directive('gmColorizeTag', GmColorizeTagDirective)
module.directive('gmKalendae', GmKalendaeDirective)
module.directive('gmSortable', GmSortableDirective)
module.directive('gmPopover', ['$parse', '$compile', GmPopoverDirective])
#this module is commented because is deprecated.
#module.directive('gmModal', ["$parse", "$compile", GmModalDirective])
#TODO: this directive does not works properly
#module.directive('gmFlashMessage', GmFlashMessageDirective)
module.directive('gmChecksleyForm', ['$parse', '$compile', '$window', GmChecksleyFormDirective])
module.directive('gmChecksleySubmitButton', [GmChecksleySubmitButtonDirective])
module.directive('gmTagsInput', [GmTagsInputDirective])
