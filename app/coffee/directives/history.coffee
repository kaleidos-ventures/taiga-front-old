GmHistoryDirective = ($compile, $rootScope, $i18next) ->
    restrict: "A"
    require: "?ngModel"
    link: (scope, elm, attrs, ngModel) ->
        resolvers = {
            userstory: (name, value) ->
                return switch name
                    when "status"
                        if value
                            return scope.constants.usStatuses[value].name
                        return null
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    else value
            issue: (name, value) ->
                return switch name
                    when "priority"
                        if value
                            return scope.constants.priorities[value].name
                        return null
                    when "status"
                        if value
                            return scope.constants.issueStatuses[value].name
                        return null
                    when "severity"
                        if value
                            return scope.constants.severities[value].name
                        return null
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    when "assigned_to"
                        if value
                            return scope.constants.users[value].full_name
                        return $i18next.t("common.unassigned")
                    else value
            task: (name, value) ->
                return switch name
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    when "status"
                        if value
                            return scope.constants.taskStatuses[value].name
                        return null
                    when "assigned_to"
                        if value
                            return scope.constants.users[value].full_name
                        return $i18next.t("common.unassigned")
                    else value
        }

        fields = {
            userstory: ["status", "tags", "subject", "description", "client_requirement",
                        "team_requirement"]
            issue: ["type", "status", "priority",  "severity", "assigned_to", "tags"
                    "subject", "description"]
            task: ["status", "assigned_to", "tags", "subject", "description", "is_iocaine"]
        }

        makeChangeItem = (name, field, type) ->
            change = {
                name: field.name
                new: resolvers[type](name, field.new)
                old: resolvers[type](name, field.old)
            }

            return change

        makeHistoryItem = (item, type) ->
            if item.type is 0
                action = "add"
            else if item.type is 1
                action = "update"
            else if item.type is 2
                action = "delete"
            else
                action = ""

            changes = Lazy(fields[type])
                        .map((name) -> {name: name, field: item.changed_fields[name]})
                        .reject((x) -> _.isEmpty(x["field"]))
                        .map((x) -> makeChangeItem(x["name"], x["field"], type))

            changesArray = changes.toArray()
            if item.comment.length == 0 and changesArray.length == 0
                return null

            user = scope.constants.users[item.user]
            if user?
                changed_by = user
            else
                changed_by = {full_name: "The Observer"}

            historyItem = {
                action: action
                changes: changesArray
                by: changed_by
                modified_date: item.created_date
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
            historyItems = makeHistoryItems(items.models, type).toArray()

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
module.directive("gmHistory", ['$i18next', GmHistoryDirective])
