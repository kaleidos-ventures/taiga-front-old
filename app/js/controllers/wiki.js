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
            $scope.page = page;
            $scope.content = page.content;
        }, function() {
            $scope.formOpened = true;
        });

    $scope.savePage = function() {
        if ($scope.page === undefined) {
            var content = $scope.content;

            rs.createWikiPage(projectId, slug, content).then(function(page) {
                $scope.page = page;
                $scope.content = page.content;

                $scope.formOpened = false;
            });
        } else {
            $scope.page.content = $scope.content;
            $scope.page.save().then(function() {
                $scope.formOpened = false;
            });
        }
    };

    $scope.openEditForm = function() {
        $scope.formOpened = true;
        $scope.content = $scope.page.content;
    };

    $scope.discartCurrentChanges = function() {
        $scope.formOpened = false;
        $scope.content = $scope.page.content;
    };
};

WikiController.$inject = ['$scope', '$rootScope', '$location', '$routeParams', 'resource'];
