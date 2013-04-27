@DashboardController = ($scope, $rootScope, $routeParams, $q, rs) ->
    # Global Scope Variables
    $rootScope.pageSection = 'dashboard'
    $rootScope.pageBreadcrumb = ["Project", "Dashboard"]
    $rootScope.projectId = $routeParams.pid
    $scope.sprintId = $routeParams.sid
    $scope.statuses = []

    projectId = $routeParams.pid
    sprintId = $routeParams.sid || 1

    formatUserStoryTasks = ->
        $scope.usTasks = {}
        _.each $scope.userstories, (us) ->
            $scope.usTasks[us.id] = {}
            _.each $scope.statuses, (status) ->
                $scope.usTasks[us.id][status.id] = []

        _.each $scope.tasks, (task) ->
            $scope.usTasks[task.user_story][task.status].push(task)

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($rootScope.constants.points)

        totalTasks = $scope.tasks.length
        totalUss = $scope.userstoriesList.length
        totalPoints = 0
        completedPoints = 0
        compledUss = 0
        completedTasks = 0

        _.each $scope.userstoriesList, (us) ->
            totalPoints += pointIdToOrder(us.points)

        _.each $scope.tasks, (task) ->
            completedTasks +=1 if $scope.statuses[task.status].is_closed

        _.each $scope.usTasks, (statuses, usId) ->
            hasOpenTasks = false

            completedTasks = 0
            totalTasks = 0

            _.each statuses, (tasks, statusId) ->
                totalTasks += tasks.length

                if $scope.statuses[statusId].is_closed
                    completedTasks += tasks.length
                else if tasks.length > 0
                    hasOpenTasks = true

            compledUss += 1 if hasOpenTasks is true

            us = $scope.userstories[usId]
            points = pointIdToOrder(us.points)

            completedPoints += ((completedTasks * points) / totalTasks) || 0

        $scope.stats =
            totalPoints: totalPoints
            completedPoints: completedPoints.toFixed(0)
            percentageCompletedPoints: ((completedPoints*100) / totalPoints).toFixed(1)
            totalUss: totalUss
            compledUss: compledUss.toFixed(0)
            totalTasks: totalTasks
            completedTasks: completedTasks

    $q.all([
        rs.getTaskStatuses(projectId),
        rs.getMilestoneUserStories(projectId, sprintId),
        rs.getUsPoints(projectId),
        rs.getTasks(projectId, sprintId),
        rs.getUsers(projectId)
    ]).then((results) ->
        statuses = results[0]
        userstories = results[1]
        points = results[2]
        tasks = results[3]
        users = results[4]

        $rootScope.constants.usersList = _.sortBy(users, "id")

        $scope.statusesList = _.sortBy(statuses, 'id')
        $scope.userstoriesList = _.sortBy(userstories, 'id')

        $scope.tasks = tasks
        $scope.userstories = {}
        $scope.statuses = {}

        _.each(statuses, (status) -> $scope.statuses[status.id] = status)
        _.each(userstories, (us) -> $scope.userstories[us.id] = us)
        _.each(points, (item) -> $rootScope.constants.points[item.id] = item)
        _.each(users, (item) -> $rootScope.constants.users[item.id] = item)

        ## HACK: must be deleted on the near future
        #$scope.tasks = _.filter tasks, (task) ->
        #    return (task.milestone == sprintId && task.project == projectId)

        formatUserStoryTasks()
        calculateStats()
        initializeEmptyForm()
    )

    initializeEmptyForm = ->
        $scope.form = {"status": $scope.statusesList[0].id}

    $scope.submitTask = ->
        form = _.extend({tags:[]}, $scope.form, {"user_story": this.us.id})

        rs.createTask(projectId, form).then (model) ->
            $scope.tasks.push(model)

            formatUserStoryTasks()
            calculateStats()
            initializeEmptyForm()

        # Notify to all modal directives
        # for close all opened modals.
        $scope.$broadcast("modals:close")

    $scope.$on "sortable:changed", ->
        _.each $scope.usTasks, (statuses, usId) ->
            _.each statuses, (tasks, statusId) ->
                _.each tasks, (task) ->
                    task.user_story = parseInt(usId, 10)
                    task.status = parseInt(statusId, 10)

                    task.save() if task.isModified()

        calculateStats()

@DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource']


@DashboardTaskController = ($scope, $q) ->
    $scope.updateTaskAssignation = (task, id) ->
        task.assigned_to = id ? id : null
        task.save()

@DashboardTaskController.$inject = ['$scope', '$q']
