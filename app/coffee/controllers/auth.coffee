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

class LoginController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams',
                 'resource', '$gmAuth', '$i18next', '$favico']

    constructor: (@scope, @rootScope, @location, @routeParams, @rs, @gmAuth, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'login'

    getTitle: ->
        @i18next.t('login.login-title')

    initialize: ->
        @scope.form = {}
        @scope.success = false
        @scope.error = false
        @scope.errorMessage = ''

    submit: ->
        username = @scope.form.username
        password = @scope.form.password

        @scope.loading = true
        @rs.login(username, password)
            .then(@onSuccess, @onError)
            .then =>
                @.loading = false

    onError: (data) ->
        @scope.error = true
        @scope.errorMessage = data.detail

    onSuccess: (user) ->
        if @routeParams['next'] and @routeParams['next'] != '/login'
            @location.url(@routeParams['next'])
        else
            @location.url("/")


class RecoveryController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$location", "resource", "$i18next", "$favico"]

    constructor: (@scope, @rootScope, @location, @rs, @i18n, @favico) ->
        super(scope, rootScope, favico)

    section: 'login'

    getTitle: ->
        @i18n.t('login.password-recovery-title')

    initialize: ->
        @scope.formData = {}
        @scope.success = false
        @scope.error = false

    submit: ->
        @.rs.recovery(@scope.formData.email)
            .then(@.onSuccess, @.onError)

    onError: (data) =>
        @scope.error = true
        @scope.success = false
        @scope.formData = {}
        @scope.errorMessage = data._error_message

    onSuccess: =>
        @scope.success = true
        @scope.error = false

        gm.utils.delay 2000, =>
            @.location.url("/login")
            @.scope.$apply()


class ChangePasswordController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams',
                 'resource', '$i18next', '$favico']
    constructor: (@scope, @rootScope, @location, @routeParams, @rs, @i18next, @favico) ->
        super(scope, rootscope, favico)

    section: 'login'
    getTitle: ->
        @i18next.t('login.password-change-title')

    initialize: ->
        @scope.error = false
        @scope.success = false
        @scope.formData = {}

        if @routeParams.token?
            @scope.tokenInParams = true
        else
            @scope.tokenInParams = false

    submit: ->
        token = @routeParams.token or @scope.formData.token
        promise = @rs.changePasswordFromRecovery(token, @scope.formData.password)
        promise.then =>
            @scope.success = true
            @scope.error = false

            gm.utils.delay 1000, =>
                @location.url("/login")
                @scope.$apply()

        promise.then null, (data) =>
            @scope.error = true
            @scope.success = false
            @scope.formData = {}
            @scope.errorMessage = data.detail


class ProfileController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$gmAuth', '$gmFlash', 'resource',
                 '$gmConfig', '$i18next', "$favico"]

    constructor: (@scope, @rootScope, @gmAuth, @gmFlash, @rs, @gmConfig, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'profile'
    getTitle: ->
        @i18next.t('profile.profile-title')

    initialize: ->
        @favico.reset()
        @rootScope.pageTitle = @i18next.t('profile.profile')
        @rootScope.projectId = null
        @rootScope.pageSection = 'profile'
        @rootScope.pageBreadcrumb = [
            ["Taiga", @rootScope.urls.projectsUrl()],
            [@i18next.t("profile.profile"), null]
        ]
        @scope.notificationLevelOptions = @gmConfig.get("notificationLevelOptions")
        @scope.languageOptions = @gmConfig.get("languageOptions")

        @scope.formData = {}
        @scope.authForm = @scope.auth

        if not @scope.authForm.notify_level?
            @scope.authForm.notify_level = _.keys(@scope.notificationLevelOptions)[0]
        if not @scope.authForm.default_language?
            @scope.authForm.default_language = _.keys(@scope.languageOptions)[0]

    submitProfile: (form) ->
        promise = form.save()

        promise.then (user) =>
            @gmAuth.setUser(user)
            @gmFlash.info(@i18next.t('profile.saved-successful'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data

    submitPassword: ->
        promise = @rs.changePasswordForCurrentUser(@scope.formData.password)

        promise.then (data) =>
            @gmFlash.info(@i18next.t('profile.password-changed-successful'))

        promise.then null, (data) =>
            @scope.checksleyErrors = data


class PublicRegisterController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$location", "resource", "$data",
                 "$gmAuth", "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @location, @rs, @data, @gmAuth, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'login'
    getTitle: ->
        @i18next.t('register.register')

    initialize: ->
        @scope.form = {"type": "public"}
        @scope.$watch "site.data.public_register", (value) ->
            if value == false
                @location.url("/login")

    submit: ->
        form = _.clone(@scope.form)

        promise = @rs.register(form)
        promise.then (user) =>
            @location.url("/")

        promise.then null, (data) =>
            @scope.checksleyErrors = data
            @scope.error = true
            @scope.errorMessage = data._error_message or data._error_type


class InvitationRegisterController extends TaigaPageController
    @.$inject = ["$scope", "$routeParams", "$rootScope", "$location",
                 "resource", "$data", "$gmAuth", "$i18next", '$favico']
    constructor: (@scope, @params, @rootScope, @location, @rs, @data, @gmAuth, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'login'
    getTitle: ->
        @i18next.t('register.register')

    initialize: ->
        @scope.form = {existing: "on", "type": "private", "token": @params.token}

    submit: ->
        form = _.clone(@scope.form)
        form.existing = if form.existing == "on" then true else false

        promise = @rs.register(form)
        promise.then (user) =>
            @location.url("/")

        promise.then null, (data) =>
            @scope.checksleyErrors = data
            @scope.error = true
            @scope.errorMessage = data._error_message or data._error_type

moduleDeps = ['taiga.services.resource', 'taiga.services.data',
              'taiga.services.auth', 'i18next', 'favico', 'gmConfig',
              'ngRoute']
module = angular.module("taiga.controllers.auth", moduleDeps)
module.controller("LoginController", LoginController)
module.controller("RecoveryController", RecoveryController)
module.controller("ChangePasswordController", ChangePasswordController)
module.controller("ProfileController", ProfileController)
module.controller("PublicRegisterController", PublicRegisterController)
module.controller("InvitationRegisterController", InvitationRegisterController)
