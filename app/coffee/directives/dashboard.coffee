dashboardModule = angular.module('greenmine.directives.dashboard', [])

gmDashboardGraphConstructor = ($parse, rs) -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        getDaysLabels = (startDay, numOfDays) ->
            labels = []
            for dayNum in [0..numOfDays]
                day = moment(startDay)
                day.add('days', dayNum)
                labels.push(day.date())
            return labels

        getOptimalList = (totalPoints, numOfDays) ->
            (totalPoints-((totalPoints/(numOfDays-1))*dayNum) for dayNum in [0..numOfDays-1])

        getUSCompletionList = (userStories, numOfDays, startDay) ->
            pointIdToOrder = greenmine.utils.pointIdToOrder(scope.constants.points)
            points = []

            for dayNum in [0..numOfDays-1]
                day = moment(startDay)
                day.add('days', dayNum)
                if day > moment().add('days', 1)
                    break

                finishedUserStories = _.filter(userStories, (obj) ->
                    if obj.finish_date
                        return day > moment(obj.finish_date)
                    else
                        return false
                )

                points.push(_.reduce(finishedUserStories, ((total, us) -> return total + pointIdToOrder(us.points)), 0))
            return points


        width = element.width()
        height = element.width()

        chart = $("<canvas />").css("width", width).css("height", height).attr("id", "dashboard-chart")

        element.empty()
        element.append(chart)

        ctx = $("#dashboard-chart").get(0).getContext("2d")

        options =
            animation: false,
            bezierCurve: false

        numOfDays = (moment(scope.milestone.estimated_finish) - moment(scope.milestone.estimated_start))/ (24*60*60*1000)

        data =
            labels : getDaysLabels(scope.milestone.estimated_start, numOfDays)
            datasets : [
                {
                    fillColor : "rgba(220,220,220,0.5)",
                    strokeColor : "rgba(220,220,220,1)",
                    pointColor : "rgba(220,220,220,1)",
                    pointStrokeColor : "#fff",
                    data : getOptimalList(scope.stats.totalPoints, numOfDays)
                },
                {
                    fillColor : "rgba(151,187,205,0.5)",
                    strokeColor : "rgba(151,187,205,1)",
                    pointColor : "rgba(151,187,205,1)",
                    pointStrokeColor : "#fff",
                    data : getUSCompletionList(scope.milestone.user_stories, numOfDays, scope.milestone.estimated_start)
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'statuses', (value) ->
        if scope.statuses and scope.milestone
            redrawChart()

dashboardModule.directive("gmDashboardGraph", ["$parse", "resource", gmDashboardGraphConstructor])
