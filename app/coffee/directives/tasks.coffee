
GmTaskHistoryDirective = ($compile, $rootScope) ->
    restrict: "A"
    require: "?ngModel"
    link: (scope, elm, attrs, ngModel) ->
        validFields = ["status", "tags", "subject", "description",
                       "assigned_to"]

        baseTemplate = _.str.trim(angular.element("#change-template").html())
        target = angular.element(elm)

        resolveValue = (name, value) ->
            return switch name
                when "status" then scope.constants.taskStatuses[value].name
                when "assigned_to"
                    if value == null
                        return "Unassigned"
                    return scope.constants.users[value].email
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

            cachedScope = $scope = scope.$new(true)
            $scope.historyItems = _historyItems

            template = angular.element($.parseHTML(baseTemplate))
            $compile(template)($scope)
            target.append(template)

        ngModel.$render = () ->
            render ngModel.$viewValue or []

module = angular.module('greenmine.directives.tasks', [])
module.directive("gmTaskHistory", GmTaskHistoryDirective)
