var LoginController = function($scope, $rootScope, $location, rs) {
    $rootScope.pageSection = 'login';
    $scope.form = {};

    $scope.submit = function() {
        rs.login($scope.form.username, $scope.form.password).then(function(data) {
            $location.url("/");
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
