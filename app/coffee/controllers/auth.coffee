# Copyright 2013 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LoginController = ($scope, $rootScope, $location, rs, storage) ->
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


RegisterController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'


RecoveryController = ($scope, $rootScope, url) ->
    $rootScope.pageSection = 'login'


module = angular.module("greenmine.controllers.auth", [])
module.controller("LoginController", ['$scope', '$rootScope', '$location', 'resource', 'storage', LoginController])
module.controller("RegisterController", ['$scope', '$rootScope', 'url', RegisterController])
module.controller("RecoveryController", ['$scope', '$rootScope', 'url', RecoveryController])
