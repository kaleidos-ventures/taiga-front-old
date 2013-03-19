var LoginController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'login';

    $scope.submit = function() {
        console.log("submit");
    };
};

LoginController.$inject = ['$scope', '$rootScope', 'url'];


var RegisterController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'login';
};

RegisterController.$inject = ['$scope', '$rootScope', 'url'];


var RecoveryController = function($scope, $rootScope, url) {
    $rootScope.pageSection = 'login';
};

RecoveryController.$inject = ['$scope', '$rootScope', 'url'];
