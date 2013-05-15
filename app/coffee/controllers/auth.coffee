@LoginController = ($scope, $rootScope, $location, rs, storage) ->
    $rootScope.pageSection = 'login'

    $scope.form = {}
    $scope.submit = ->
        username = $scope.form.username
        password = $scope.form.password

        $scope.loading = true

        onSuccess = (data) ->
            storage.set("userInfo", data)
            $location.url("/")

        onError = (data) ->
            $scope.error = true
            $scope.errorMessage = data.detail

        promise = rs.login(username, password)
        promise = promise.then onSuccess, onError
        promise.then ->
            $scope.loading = false

@LoginController.$inject = ['$scope', '$rootScope', '$location', 'resource', 'storage']


@RegisterController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'

@RegisterController.$inject = ['$scope', '$rootScope', 'url']


@RecoveryController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'

@RecoveryController.$inject = ['$scope', '$rootScope', 'url']
