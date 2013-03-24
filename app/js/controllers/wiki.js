var WikiController = function($scope, $rootScope, $routeParams, rs) {
    $rootScope.pageSection = 'wiki';
    $rootScope.pageBreadcrumb = ["Project", "Wiki", $routeParams.slug];
};

WikiController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];
