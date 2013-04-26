var QuestionsController = function($scope, $rootScope, $routeParams, $filter, $q, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'questions';
    $rootScope.pageBreadcrumb = ["Project", "Questions"];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    var projectId = $rootScope.projectId;

    $scope.filtersOpened = false;
    $scope.issueFormOpened = false;
};

QuestionsController.$inject = ['$scope', '$rootScope', '$routeParams', '$filter', '$q', 'resource'];




var QuestionsViewController = function($scope, $rootScope, $routeParams, $q, rs) {
    $rootScope.pageSection = 'questions';
    $rootScope.pageBreadcrumb = ["Project", "Questions", "#" + $routeParams.issueid];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    var projectId = $rootScope.projectId;
    var issueId = $routeParams.issueid;

};

QuestionsViewController.$inject = ['$scope', '$rootScope', '$routeParams', '$q', 'resource'];
