_.mixin({
    findByValues: (collection, property, values) ->
        return _.filter(collection, (item) ->
            return _.contains(values, item[property])
        )
})


GmHistoryDirective = ($compile, $rootScope, $i18next) ->
    restrict: "A"
    require: "?ngModel"
    link: (scope, elm, attrs, ngModel) ->
        resolvers = {
            userstory: (name, value) ->
                return switch name
                    when "status"
                        if value
                            try
                                return scope.constants.usStatuses[value].name
                            catch
                                return null
                        return null
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    when "team_requirement", "client_requirement", "is_blocked"
                        if value is true
                            return $i18next.t("common.yes")
                        else if value is false
                            return $i18next.t("common.no")
                        else null
                    when "watchers"
                        if value
                            watchers_ids = _.map(value, (v) -> parseInt(v, 10))
                            watchers = _.findByValues(scope.constants.users, "id", watchers_ids)
                            return _.map(watchers, "full_name").join(", ")
                        return null
                    else value
            issue: (name, value) ->
                return switch name
                    when "type"
                        if value
                            try
                                return scope.constants.issueTypes[value].name
                            catch
                                return null
                        return null
                    when "priority"
                        if value
                            try
                                return scope.constants.priorities[value].name
                            catch
                                return null
                        return null
                    when "status"
                        if value
                            try
                                return scope.constants.issueStatuses[value].name
                            catch
                                return null
                        return null
                    when "severity"
                        if value
                            try
                                return scope.constants.severities[value].name
                            catch
                                return null
                        return null
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    when "assigned_to"
                        if value
                            try
                                return scope.constants.users[value].full_name
                            catch
                                return null
                        return $i18next.t("common.unassigned")
                    when "is_blocked"
                        if value is true
                            return $i18next.t("common.yes")
                        else if value is false
                            return $i18next.t("common.no")
                        else null
                    when "watchers"
                        if value
                            watchers_ids = _.map(value, (v) -> parseInt(v, 10))
                            watchers = _.findByValues(scope.constants.users, "id", watchers_ids)
                            return _.map(watchers, "full_name").join(", ")
                        return null
                    else value
            task: (name, value) ->
                return switch name
                    when "tags"
                        if value
                            return value.join(", ")
                        else null
                    when "status"
                        if value
                            try
                                return scope.constants.taskStatuses[value].name
                            catch
                                return null
                        return null
                    when "assigned_to"
                        if value
                            try
                                return scope.constants.users[value].full_name
                            catch
                                return null
                        return $i18next.t("common.unassigned")
                    when "is_iocaine", "is_blocked"
                        if value is true
                            return $i18next.t("common.yes")
                        else if value is false
                            return $i18next.t("common.no")
                        else null
                    when "watchers"
                        if value
                            watchers_ids = _.map(value, (v) -> parseInt(v, 10))
                            watchers = _.findByValues(scope.constants.users, "id", watchers_ids)
                            return _.map(watchers, "full_name").join(", ")
                        return null
                    else value
        }

        fields = {
            userstory: ["status", "tags", "subject", "description", "client_requirement",
                        "team_requirement", "is_blocked", "blocked_note", "watchers"]
            issue: ["type", "status", "priority",  "severity", "assigned_to", "tags"
                    "subject", "description", "is_blocked", "blocked_note", "watchers"]
            task: ["status", "assigned_to", "tags", "subject", "description", "is_iocaine",
                   "is_blocked", "blocked_note", "watchers"]
        }

        makeChangeItem = (name, field, type) ->
            new_val = resolvers[type](name, field.new)
            old_val = resolvers[type](name, field.old)

            if new_val or old_val
                change = {
                    name: field.name
                    new: new_val
                    old: old_val
                }
                return change
            return null

        makeHistoryItem = (item, type) ->
            changes = _(fields[type]).map((name) -> {name: name, field: item.changed_fields[name]})
                                     .reject((x) -> _.isEmpty(x["field"]))
                                     .map((x) -> makeChangeItem(x["name"], x["field"], type))
                                     .reject((x) -> x is null)
            changesArray = changes.value()

            if item.comment.length == 0 and changesArray.length == 0
                return null

            user = scope.constants.users[item.user]
            if user?
                changed_by = user
            else
                changed_by = {full_name: "The Observer"}

            historyItem = {
                changes: changesArray
                by: changed_by
                modified_date: item.created_date
                comment: item.comment
            }

            return historyItem

        makeHistoryItems = (rawItems, type)  ->
            return _(rawItems).map((x) -> makeHistoryItem(x, type))
                              .reject((x) -> _.isNull(x))
                              .value()


        baseTemplate = _.str.trim(angular.element("#change-template").html())

        element = angular.element(elm)
        target = element.find(".history-items-container")

        type = attrs.gmHistory
        cachedScope = null

        render = (items) ->
            # Initial Clear
            cachedScope.$destroy() if cachedScope != null

            # Make new list
            historyItems = makeHistoryItems(items.models, type)

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

module = angular.module('taiga.directives.history', ['i18next'])
module.directive("gmHistory", ['$compile', '$rootScope', '$i18next', GmHistoryDirective])
