var WikiController = function($scope, $rootScope, $routeParams, rs) {
    $rootScope.pageSection = 'wiki';
    $rootScope.pageBreadcrumb = ["Project", "Wiki", $routeParams.slug];
    $rootScope.projectId = parseInt($routeParams.pid, 10);


    var projectId = $rootScope.projectId;
    var slug = $routeParams.slug;

    rs.getWikiPage(projectId, slug).
        then(function(page) {
            $scope.$apply(function() {
                $scope.page = page;
            });
        }, function(data) {
        });
};

WikiController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];
