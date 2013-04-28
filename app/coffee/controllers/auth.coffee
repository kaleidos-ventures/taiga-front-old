@LoginController = ($scope, $rootScope, $location, rs) ->
    $rootScope.pageSection = 'login'

    $scope.form = {}
    $scope.submit = ->
        username = $scope.form.username
        password = $scope.form.password

        $scope.loading = true

        promise = rs.login(username, password).then (data) ->
            $location.url("/")
        , (data) ->
            $scope.error = true
            $scope.errorMessage = data.detail

        promise.then ->
            $scope.loading = false

@LoginController.$inject = ['$scope', '$rootScope', '$location', 'resource']


@RegisterController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'

@RegisterController.$inject = ['$scope', '$rootScope', 'url']


@RecoveryController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'

@RecoveryController.$inject = ['$scope', '$rootScope', 'url']
