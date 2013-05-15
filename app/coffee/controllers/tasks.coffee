@TasksViewController = ($scope, $rootScope, $routeParams, $q, rs) ->
    $rootScope.pageSection = 'tasks'
    $rootScope.pageBreadcrumb = ["Project", "Tasks", "#" + $routeParams.taskid]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    projectId = $rootScope.projectId
    taskId = $routeParams.taskid

    promise = $q.all [
        rs.getTaskStatuses(projectId),
        rs.getUsers(projectId),
        rs.getTaskAttachments(projectId, taskId),
        rs.getTask(projectId, taskId)
    ]

    promise.then (results) ->
        taskStatuses = results[0]
        users = results[1]
        attachments = results[2]
        task = results[3]

        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)
        _.each(taskStatuses, (item) -> $rootScope.constants.status[item.id] = item)

        $rootScope.constants.statusList = _.sortBy(taskStatuses, "order")
        $rootScope.constants.usersList = _.sortBy(users, "id")

        $scope.attachments = attachments
        $scope.task = task
        $scope.form = _.extend({}, $scope.task._attrs)

    $scope.task = {}
    $scope.form = {}
    $scope.updateFormOpened = false

    $scope.isSameAs = (property, id) ->
        return ($scope.task[property] == parseInt(id, 10))

    $scope.save = ->
        defered = $q.defer()
        promise = defered.promise

        if $scope.attachment
            rs.uploadTaskAttachment(projectId, taskId, $scope.attachment).then (data)->
                defered.resolve(data)
        else
            defered.resolve(null)

        promise = promise.then () ->
            _.each $scope.form, (value, key) ->
                $scope.task[key] = value
                return

            return $scope.task.save()

        return promise.then (task) ->
            task.refresh()

@TasksViewController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource']
