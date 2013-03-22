var DashboardController = function($scope, $rootScope, $routeParams, url) {
    $rootScope.pageSection = 'backlog';

    $scope.milestones = [
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20},
        {name:"Milestone1", percentage_completed:20, total_points:100, completed_points:20}
    ];

    $scope.userstories = [
        {id:1, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10,
            tasks: [
                {id:1, name:"Thundercats veniam occaecat, freegan keytar DIY readymade photo booth", status_id:"new"},
                {id:1, name:"Fingerstache irure high life, chambray officia selvage before they sold out quinoa hashtag.", status_id:"inprogress"},
                {id:1, name:"Odio bicycle rights sriracha irure meh messenger bag.", status_id:"inprogress"},
                {id:1, name:"Do you need some dummy text?", status_id:"readytest"},
                {id:1, name:"Gentrify excepteur williamsburg art party mixtape bicycle rights.", status_id:"rejected"}
            ]
        },
        {id:2, points:2, priority:"hight", tags:[{"name": "tag1", id:1}, {"name": "tag2", id:2}], subject:"Sample User story 1", order:10,
            tasks: [
                {id:1, name:"Thundercats veniam occaecat, freegan keytar DIY readymade photo booth", status_id:"new"},
                {id:1, name:"Fingerstache irure high life, chambray officia selvage before they sold out quinoa hashtag.", status_id:"inprogress"},
                {id:1, name:"Odio bicycle rights sriracha irure meh messenger bag.", status_id:"inprogress"},
                {id:1, name:"Do you need some dummy text?", status_id:"readytest"},
                {id:1, name:"Gentrify excepteur williamsburg art party mixtape bicycle rights.", status_id:"rejected"}
            ]
        },
    ];


    $scope.formatUserStoryTasks = function() {
        var usTasks = {};
        var statuses = ['new','inprogress', 'readytest', 'finished', 'rejected'];

        _.each($scope.userstories, function(item) {
            if (usTasks[item.id] === undefined) {
                usTasks[item.id] = {};
                _.each(statuses, function(statusname){
                    usTasks[item.id][statusname] = [];
                });
            }

            _.each(item.tasks, function(task) {
                usTasks[item.id][task.status_id].push(task);
            });
        });

        $scope.usTasks = usTasks
        console.log(usTasks);
    };

    $scope.formatUserStoryTasks();
};

DashboardController.$inject = ['$scope', '$rootScope', '$routeParams', 'url'];
