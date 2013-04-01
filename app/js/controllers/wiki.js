var WikiController = function($scope, $rootScope, $location, $routeParams, rs) {
    $rootScope.pageSection = 'wiki';
    $rootScope.pageBreadcrumb = ["Project", "Wiki", $routeParams.slug];
    $rootScope.projectId = parseInt($routeParams.pid, 10);

    $scope.formOpened = false;
    $scope.form = {};

    var projectId = $rootScope.projectId;
    var slug = $routeParams.slug;

    rs.getWikiPage(projectId, slug).
        then(function(page) {
            $scope.$apply(function() {
                $scope.page = page;
            });
        }, function() {
            $scope.$apply(function() {
                $scope.formOpened = true;
            });
        });

    $scope.savePage = function() {
        if ($scope.form.id === undefined) {
            var content = $scope.form.content;
            rs.createWikiPage(projectId, slug, content).then(function(page) {
                $scope.page = page;
                $scope.formOpened = false;
                $scope.$apply();
            });
        } else {
            $scope.page.save().then(function() {
                $scope.formOpened = false;
                $scope.$apply();
            });
        }
    };

    $scope.editPage = function() {
        $scope.formOpened = true;
        $scope.form = $scope.page;
    };
};

WikiController.$inject = ['$scope', '$rootScope', '$location', '$routeParams', 'resource'];
