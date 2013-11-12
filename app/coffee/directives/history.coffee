GmHistoryDirective = ($compile, $rootScope) ->
    restrict: "A"
    require: "?ngModel"
    link: (scope, elm, attrs, ngModel) ->
        resolvers = {
            userstory: (name, value) ->
                return switch name
                    when "status" then scope.constants.usStatuses[value].name
                    else value

            issue: (name, value) ->
                return switch name
                    when "priority" then scope.constants.priorities[value].name
                    when "status" then scope.constants.issueStatuses[value].name
                    when "severity" then scope.constants.severities[value].name
                    when "assigned_to"
                        if value == null
                            return "Unassigned"
                        return scope.constants.users[value].full_name
                    else value
            task: (name, value) ->
                return switch name
                    when "status" then scope.constants.taskStatuses[value].name
                    when "assigned_to"
                        if value == null
                            return "Unassigned"
                        return scope.constants.users[value].full_name
                    else value
        }

        fields = {
            userstory: ["status", "tags", "subject"]
            issue: ["priority", "status", "tags", "subject", "assigned_to"]
            task: ["status", "tags", "subject", "assigned_to"]
        }

        makeChangeItem = (name, field, type) ->
            change = {
                name: name
                new: resolvers[type](name, field.new)
                old: resolvers[type](name, field.old)
            }

            return change

        makeHistoryItem = (item, type) ->
            changes = Lazy(fields[type])
                        .map((name) -> {name: name, field: item[name]})
                        .reject((x) -> _.isEmpty(x["field"]))
                        .map((x) -> makeChangeItem(x["name"], x["field"], type))

            changesArray = changes.toArray()
            if item.comment.length == 0 and changesArray.length == 0
                return null

            historyItem = {
                changes: changesArray
                by: item.by
                modified_date: item.modified_date
                comment: item.comment
            }

            return historyItem

        makeHistoryItems = (rawItems, type)  ->
            return Lazy(rawItems)
                        .map((x) -> makeHistoryItem(x, type))
                        .reject((x) -> _.isNull(x))

        baseTemplate = _.str.trim(angular.element("#change-template").html())

        element = angular.element(elm)
        target = element.find(".history-items-container")

        type = attrs.gmHistory
        cachedScope = null

        render = (items) ->
            # Initial Clear
            cachedScope.$destroy() if cachedScope != null

            # Make new list
            historyItems = makeHistoryItems(items, type).toArray()

            if historyItems.length == 0
                element.hide()
            else
                target.empty()
                element.show()

                cachedScope = $scope = scope.$new(true)
                template = angular.element($.parseHTML(baseTemplate))

                $scope.historyItems = historyItems
                $compile(template)($scope)

                target.append(template)

        ngModel.$render = () ->
            render(ngModel.$viewValue or [])

module = angular.module('greenmine.directives.history', [])
module.directive("gmHistory", GmHistoryDirective)
