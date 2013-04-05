var LoginController = function($scope, $rootScope, $location, rs) {
    $rootScope.pageSection = 'login';

    $scope.form = {};
    $scope.submit = function() {
        var username = $scope.form.username;
        var password = $scope.form.password;

        $scope.loading = true

        rs.login(username, password).then(function(data) {
            $location.url("/");
        }, function(data) {
            $scope.error = true;
            $scope.errorMessage = data.detail
        }).then(function() {
            $scope.loading = false;
        });
    };
};

LoginController.$inject = ['$scope', '$rootScope', '$location', 'resource'];


var RegisterController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'login';
};

RegisterController.$inject = ['$scope', '$rootScope', 'url'];


var RecoveryController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'login';
};

RecoveryController.$inject = ['$scope', '$rootScope', 'url'];
