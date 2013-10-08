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
                if isNaN(result[index] - milestone.closed_points["1"])
                    result.push(0)
                else
                    result.push(result[index] - milestone.closed_points["1"])
            )
            return result

        getTeamIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = [0]
            _.each(listOfMilestones, (milestone, index) ->
                if isNaN(result[index] - milestone.team_increment_points["1"])
                    result.push(0)
                else
                    result.push(result[index] - milestone.team_increment_points["1"])
            )
            return result

        getClientIncrementPoints = (listOfMilestones) ->
            listOfMilestones = _.filter(listOfMilestones, (milestone) -> moment(milestone.finish_date) <= moment())
            result = getTeamIncrementPoints(listOfMilestones)
            _.each(listOfMilestones, (milestone, index) ->
                if isNaN(result[index] - milestone.client_increment_points["1"])
                    result.push(0)
                else
                    result[index+1] += (result[index] - milestone.client_increment_points["1"])
            )
            return result

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
            labels : getLabels(scope.project.list_of_milestones, scope.project.total_milestones)
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : getOptimalList(scope.project.total_story_points, scope.project.total_milestones)
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
        else if menuSection is "admin"
            element.find("li.admin").addClass("selected")
        else if menuSection is "search"
        else


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


SearchBoxDirective = ($rootScope, $location) ->
    link: (scope, elm, attrs) ->
        form = elm.find("form")
        form.on "submit", (event) ->
            event.preventDefault()

            action = form.attr('action')
            value = form.find("input").val()

            scope.$apply ->
                path = $rootScope.urls.searchUrl(scope.projectId, true)
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
    restrict: "A"
    link: (scope, element, attrs) ->
        fn = $parse(attrs.gmPopover)

        autoHide = element.data('auto-hide')
        placement = element.data('placement') or 'right'

        acceptSelector = element.data('accept-selector') or '.popover-content .button-success, .popover-content .btn-accept'
        cancelSelector = element.data('cancel-selector') or '.popover-content .button-delete'

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
                    element.popover('hide')
                    element.data('state', 'closed')


            next = element.next()
            next.on "click", acceptSelector, (event) ->
                event.preventDefault()

                target = angular.element(event.currentTarget)
                id = target.data('id')

                scope.$apply ->
                    fn(scope, {"selectedId": id})

                element.popover('hide')
                next.off()

            next.on "click", cancelSelector, (event) ->
                element.popover('hide')
                next.off()

            if autoHide
                element.data('state', 'closing')
                _.delay(closeHandler, 2000)

                next.on "mouseleave", ".popover-inner", (event) ->
                    element.data('state', 'closing')
                    _.delay(closeHandler, 200)

                next.on "mouseenter", ".popover-inner", (event) ->
                    element.data('state', 'open')


GmFlashMessageDirective = ->
    compile: (element, attrs) ->
        template = """
        <div class="flash-message-success hidden">
            <p>¡Genial! Aquí va el mensaje de confirmación </p>
        </div>
        <div class="flash-message-fail hidden">
            <p>¡Ops! Esto es embarazoso, parece que algo ha salido mal... </p>
        </div>"""

        element.html(template)
        return @.link

    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        scope.$on "flash:new", (ctx, success, message) ->
            if success
                element.find(".flash-message-success p").text(message)
                element.find(".flash-message-success").fadeIn().delay(2000).fadeOut()
            else
                element.find(".flash-message-fail p").text(message)
                element.find(".flash-message-fail").fadeIn().delay(2000).fadeOut()

            angular.element("html, body").animate({ scrollTop: 0 }, "slow");


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
        <fieldset class="us-role-points" ng-repeat="role in roles">
            {{ role.name }} (points)
            <select class="points" name="points" ng-model="form.points[role.id]" data-required="true"
                data-error-message="Required"
                ng-options="c.order as c.name for c in constants.pointsList|orderBy:'order'">
            </select>
        </fieldset>"""

        element.html(template)
        return @.link

    link: (scope, elm, attrs) ->
        if scope.form is undefined
            scope.form = {}

        if scope.form.points is undefined
            scope.form.points = {}


module = angular.module('greenmine.directives.common', [])
module.directive('gmBreadcrumb', ["$rootScope", GmBreadcrumbDirective])
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive('gmHeaderMenu', ["$rootScope", GmHeaderMenuDirective])
module.directive('gmNinjaGraph', GmNinjaGraphDirective)
module.directive('gmColorizeTag', GmColorizeTagDirective)
module.directive('gmKalendae', GmKalendaeDirective)
module.directive('gmSortable', GmSortableDirective)
module.directive('gmPopover', ['$parse', '$compile', GmPopoverDirective])
module.directive('gmFlashMessages', GmFlashMessageDirective)
module.directive('gmChecksleyForm', ['$parse', '$compile', '$window', GmChecksleyFormDirective])
module.directive('gmChecksleySubmitButton', [GmChecksleySubmitButtonDirective])
module.directive('gmTagsInput', [GmTagsInputDirective])
module.directive('gmSearchBox', ["$rootScope", "$location", SearchBoxDirective])
module.directive('gmRolePointsEdition', GmRolePointsEditionDirective)
