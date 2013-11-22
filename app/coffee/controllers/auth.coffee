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

LoginController = ($scope, $rootScope, $location, rs, $gmAuth) ->
    $rootScope.pageSection = 'login'

    $scope.form = {}
    $scope.submit = ->
        username = $scope.form.username
        password = $scope.form.password

        $scope.loading = true

        onSuccess = (user) ->
            $gmAuth.setUser(user)
            $rootScope.auth = user

            $location.url("/")

        onError = (data) ->
            $scope.error = true
            $scope.errorMessage = data.detail

        promise = rs.login(username, password)
        promise = promise.then(onSuccess, onError)
        promise.then ->
            $scope.loading = false


RegisterController = ($scope, $rootScope) ->
    $rootScope.pageSection = 'login'
    # TODO


RecoveryController = ($scope, $rootScope, $location, rs) ->
    $rootScope.pageSection = 'login'

    $scope.formData = {}
    $scope.success = false
    $scope.error = false

    $scope.submit = ->
        promise = rs.recovery($scope.formData.email)
        promise.then ->
            $scope.success = true
            $scope.error = false

            gm.utils.delay 1000, ->
                $location.url("/login")
                $scope.$apply()

        promise.then null, (data) ->
            $scope.error = true
            $scope.success = false
            $scope.formData = {}
            $scope.errorMessage = data.detail


ChangePasswordController = ($scope, $rootScope, $location, $routeParams, rs) ->
    $rootScope.pageSection = 'login'

    $scope.error = false
    $scope.success = false
    $scope.formData = {}
    if $routeParams.token?
        $scope.tokenInParams = true
    else
        $scope.tokenInParams = false


    $scope.submit = ->
        token = $routeParams.token or $scope.formData.token
        promise = rs.changePasswordFromRecovery(token, $scope.formData.password)
        promise.then ->
            $scope.success = true
            $scope.error = false

            gm.utils.delay 1000, ->
                $location.url("/login")
                $scope.$apply()

        promise.then null, (data) ->
            $scope.error = true
            $scope.success = false
            $scope.formData = {}
            $scope.errorMessage = data.detail


ProfileController = ($scope, $rootScope, $gmAuth, $gmFlash, rs, config, $i18next) ->
    $rootScope.projectId = null
    $rootScope.pageSection = 'profile'
    $rootScope.pageBreadcrumb = [
        ["Greenmine", $rootScope.urls.projectsUrl()],
        [$i18next.t("profile.profile"), null]
    ]
    $scope.notificationLevelOptions = config.notificationLevelOptions

    $scope.formData = {}

    $scope.submitProfile = ->
        promise = $rootScope.auth.save()

        promise.then (user) ->
            $gmAuth.setUser(user)
            $gmFlash.info($i18next.t('profile.saved-successful'))

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.submitPassword = ->
        promise = rs.changePasswordForCurrentUser($scope.formData.password)

        promise.then (data) ->
            $gmFlash.info($i18next.t('profile.password-changed-successful'))

        promise.then null, (data) ->
            $scope.checksleyErrors = data


module = angular.module("greenmine.controllers.auth", [])
module.controller("LoginController", ['$scope', '$rootScope', '$location', 'resource', '$gmAuth', LoginController])
module.controller("RegisterController", ['$scope', '$rootScope', RegisterController])
module.controller("RecoveryController", ['$scope', '$rootScope', '$location', 'resource', RecoveryController])
module.controller("ChangePasswordController", ['$scope', '$rootScope', '$location', '$routeParams', 'resource',  ChangePasswordController])
module.controller("ProfileController", ['$scope', '$rootScope', '$gmAuth', '$gmFlash', 'resource', 'config', '$i18next', ProfileController])
