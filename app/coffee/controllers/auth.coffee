# Copyright 2013-2014 Andrey Antukh <niwi@niwi.be>
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

class LoginController extends TaigaBaseController
    @.$inject = ['$scope', '$rootScope', '$location',
                 '$routeParams', 'resource', '$gmAuth',
                 '$i18next', '$favico']

    constructor: (@scope, @rootScope, @location, @routeParams, @rs, @gmAuth, @i18next, @favico) ->
        favico.reset()
        rootScope.pageTitle = i18next.t('login.login-title')
        rootScope.pageSection = 'login'
        @.form = {}
        super(scope)

    initialize: ->
        console.log("INITIALIZE", arguments)

    destroy: ->
        super()
        console.log("DESTROY")

    submit: ->
        username = @.form.username
        password = @.form.password

        @.loading = true
        @.rs.login(username, password)
            .then(@.onSuccess, @.onError)
            .then(=> @.loading = false)

    onError: (data) ->
        @.error = true
        @.errorMessage = data.detail

    onSuccess: (user) ->
        @.gmAuth.setUser(user)
        if @.routeParams['next'] and @.routeParams['next'] != '/login'
            @.location.url(@.routeParams['next'])
        else
            @.location.url("/")

RecoveryController = ($scope, $rootScope, $location, rs, $i18next) ->
    $rootScope.pageTitle = $i18next.t('login.password-recovery-title')
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

    return


ChangePasswordController = ($scope, $rootScope, $location, $routeParams, rs, $i18next) ->
    $rootScope.pageTitle = $i18next.t('login.password-change-title')
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

    return


ProfileController = ($scope, $rootScope, $gmAuth, $gmFlash, rs, config, $i18next, $favico) ->
    $favico.reset()
    $rootScope.pageTitle = $i18next.t('profile.profile')
    $rootScope.projectId = null
    $rootScope.pageSection = 'profile'
    $rootScope.pageBreadcrumb = [
        ["Taiga", $rootScope.urls.projectsUrl()],
        [$i18next.t("profile.profile"), null]
    ]
    $scope.notificationLevelOptions = config.notificationLevelOptions
    $scope.languageOptions = config.languageOptions

    $scope.formData = {}
    $scope.authForm = $scope.auth

    if not $scope.authForm.notify_level?
        $scope.authForm.notify_level = _.keys($scope.notificationLevelOptions)[0]
    if not $scope.authForm.default_language?
        $scope.authForm.default_language = _.keys($scope.languageOptions)[0]

    $scope.submitProfile = (form) ->
        promise = form.save()

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

    return


PublicRegisterController = ($scope, $rootScope, $location, rs, $data, $gmAuth, $i18next) ->
    $rootScope.pageTitle = $i18next.t('register.register')
    $rootScope.pageSection = 'login'
    $scope.form = {"type": "public"}

    $scope.$watch "site.data.public_register", (value) ->
        if value == false
            $location.url("/login")

    $scope.submit = ->
        form = _.clone($scope.form)

        promise = rs.register(form)
        promise.then (user) ->
            $gmAuth.setUser(user)
            $rootScope.auth = user
            $location.url("/")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    return


InvitationRegisterController = ($scope, $params, $rootScope, $location, rs, $data, $gmAuth, $i18next) ->
    $rootScope.pageTitle = $i18next.t('register.register')
    $rootScope.pageSection = 'login'
    $scope.form = {existing: "on", "type": "private", "token": $params.token}

    $scope.submit = ->
        form = _.clone($scope.form)
        form.existing = if form.existing == "on" then true else false

        promise = rs.register(form)
        promise.then (user) ->
            $gmAuth.setUser(user)
            $rootScope.auth = user
            $location.url("/")

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    return

module = angular.module("taiga.controllers.auth", [])
module.controller("LoginController", LoginController)
module.controller("RecoveryController", ['$scope', '$rootScope', '$location', 'resource', '$i18next',
                                         RecoveryController])
module.controller("ChangePasswordController", ['$scope', '$rootScope', '$location', '$routeParams', 'resource',
                                               '$i18next', ChangePasswordController])
module.controller("ProfileController", ['$scope', '$rootScope', '$gmAuth', '$gmFlash', 'resource', 'config',
                                        '$i18next', "$favico", ProfileController])
module.controller("PublicRegisterController", ["$scope", "$rootScope", "$location", "resource", "$data",
                                               "$gmAuth", "$i18next", PublicRegisterController])
module.controller("InvitationRegisterController", ["$scope", "$routeParams", "$rootScope", "$location",
                                                   "resource", "$data", "$gmAuth", "$i18next",
                                                   InvitationRegisterController])
