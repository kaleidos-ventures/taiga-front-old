GmIssuesSortDirective = ($parse) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    element.on "click", ".issue-sortable-field", (event) ->
        target = angular.element(event.currentTarget)
        if target.data('field') == scope.sortingOrder
            scope.reverse = !scope.reverse
        else
            scope.sortingOrder = target.data('field')
            scope.reverse = false

        icon = target.find("i")
        icon.removeClass("icon-chevron-up")
        icon.removeClass("icon-chevron-down")

        if scope.reverse
            icon.addClass("icon-chevron-up")
        else
            icon.addClass("icon-chevron-down")

        event.preventDefault()
        scope.$digest()


# TODO: remove, seems not used and deprecated
GmIssueChangesDirective = ->
    validFields = ["priority", "status", "severity", "tags", "subject", "description", "assigned_to"]
    template = _.template($("#change-template").html())

    return (scope, elm, attrs) ->
        element = angular.element(elm)

        handleField = (name, field) ->
            template(name: name, oldValue: field.old, newValue: field.new)

        elements = []
        for fieldName in validFields
            field = scope.h[fieldName]

            if field is undefined
                continue

            elements.push(handleField(fieldName, field))

        element.append(el) for el in elements


GmIssueHistoryDirective = ($compile, $rootScope) ->
    restrict: "A"
    require: "?ngModel"
    link: (scope, elm, attrs, ngModel) ->
        validFields = ["priority", "status", "severity", "tags",
                       "subject", "description", "assigned_to"]

        baseTemplate = _.str.trim(angular.element("#change-template").html())
        target = angular.element(elm)

        resolveValue = (name, value) ->
            return switch name
                when "priority", "status", "severity" then $rootScope.constants[name][value].name
                when "assigned_to"
                    if value == null
                        return "Unassigned"
                    return $rootScope.constants.users[value].email
                else value

        createChangeItem = (name, field) ->
            change =
                name: name
                new:  resolveValue(name, field.new)
                old: resolveValue(name, field.old)

            return change

        createHistoryItem = (item) ->
            changes = []

            for name in validFields
                field = item[name]

                if field?
                    changes.push(createChangeItem(name, field))

            historyItem =
                changes: changes
                comment: item.comment
                by: item.by
                modified_date: item.modified_date

            if historyItem.changes.length > 0 or historyItem.comment.length > 0
                return historyItem

            return null

        cachedScope = null

        render = (historyItems) ->
            # Initial Clear
            cachedScope.$destroy() if cachedScope != null
            target.empty()

            # Make new list
            _historyItems = []

            for item in historyItems
                _item = createHistoryItem(item)
                if _item?
                    _historyItems.push(_item)

            cachedScope = $scope = $rootScope.$new(true)
            $scope.historyItems = _historyItems

            template = angular.element($.parseHTML(baseTemplate))
            $compile(template)($scope)
            target.append(template)

        ngModel.$render = () ->
            render ngModel.$viewValue or []


GmPendingIssueGraphDirective = -> (scope, elm, attrs) ->
    redrawChart = () ->
        element = angular.element elm
        countIssues = (severities, issues) ->
            counter = {}
            for severity in severities
                counter[severity.id] = 0

            for issue in issues
                if not counter[issue.severity]
                    counter[issue.severity] = 1
                else
                    counter[issue.severity] += 1

            result = []
            for severity in severities
                result.push(counter[severity.id])
            result

        width = element.width()
        height = width

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "issues-chart")
        element.append(chart)

        ctx = $("#issues-chart").get(0).getContext("2d")

        options =
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = {
            labels : (severity.name for severity in scope.constants.severityList)
            datasets : [
                #Number of created bugs
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : countIssues(scope.constants.severityList, scope.issues)
                },
                #Number of resolved bugs
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : countIssues(scope.constants.severityList, _.filter(scope.issues, 'is_closed'))
                }
            ]
        }

        new Chart(ctx).Radar(data,options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


GmYourIssuesGraphDirective = -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        countIssues = (severities, issues) ->
            counter = {}
            for severity in severities
                counter[severity.id] = 0

            for issue in issues
                if not counter[issue.severity]
                    counter[issue.severity] = 1
                else
                    counter[issue.severity] += 1

            result = []
            for severity in severities
                result.push(counter[severity.id])
            result

        width = element.width()
        height = width

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "your-issues-chart")
        element.prepend(chart)

        ctx = $("#your-issues-chart").get(0).getContext("2d")

        options =
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        colors = ["#ccc", "#669933", "blue", "orange", "#CC0000"]
        counts = countIssues(scope.constants.severityList, scope.issues)
        data = []

        for x in [0..counts.length-1]
            data.push value:counts[x], color:colors[x]

        new Chart(ctx).Doughnut(data,options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


GmIssuesCreationGraphDirective = -> (scope, elm, attrs) ->
    redrawChart = () ->
        element = angular.element(elm)

        width = element.width()
        height = 320

        element.empty()
        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "issues-creation-chart")
        element.prepend(chart)

        ctx = $("#issues-creation-chart").get(0).getContext("2d")

        options =
            animation: false,
            bezierCurve: false,
            scaleFontFamily : "'ColabThi'",
            scaleFontSize : 10

        data = {
            labels : ["Sprint1","Sprint2","Sprint3","Sprint4","Sprint5","Sprint6"],
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : [10, 15, 30, 40, 20, 10]
                }
            ]
        }

        new Chart(ctx).Line(data, options)

    scope.$watch 'issues', (value) ->
        redrawChart() if value


module = angular.module('greenmine.directives.issues', [])
module.directive('gmIssuesSort', ["$parse", GmIssuesSortDirective])
module.directive("gmIssueChanges", GmIssueChangesDirective)
module.directive("gmIssueHistory", GmIssueHistoryDirective)
module.directive("gmPendingIssueGraph", GmPendingIssueGraphDirective)
module.directive("gmYourIssuesGraph", GmYourIssuesGraphDirective)
module.directive("gmIssuesCreationGraph", GmIssuesCreationGraphDirective)
