# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class LoginController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams',
                 'resource', '$gmAuth', '$i18next', '$favico', '$gmConfig']

    constructor: (@scope, @rootScope, @location, @routeParams, @rs, @gmAuth,
                  @i18next, @favico, @gmConfig) ->
        super(scope, rootScope, favico)

    section: 'login'

    getTitle: ->
        @i18next.t('login.login-title')

    initialize: ->
        @scope.form = {}
        @scope.success = false
        @scope.error = false
        @scope.errorMessage = ''

        if @routeParams.state == "github"
            @.submitWithGithub()

    redirectToGitHubAuth: () ->
        gitHubHost =  @gmConfig.get("gitHubAuthUrl")
        gitHubClientId = @gmConfig.get("gitHubClientId")
        gitHubRedirectUri = "http://localhost:9001/login"
        url = "#{gitHubHost}?client_id=#{gitHubClientId}&redirect_uri=#{gitHubRedirectUri}&state=github&scope=user:email"

        window.location.href = url

    submit: ->
        username = @scope.form.username
        password = @scope.form.password

        @scope.loading = true
        @rs.login(username, password)
            .then(@onSuccess, @onError)
            .then =>
                @.loading = false

    submitWithGithub: ->
        code = @routeParams.code

        @scope.loading = true
        @rs.gitHubLogin(code)
            .then(@onSuccess, @onError)
            .then =>
                @.loading = false

    onError: (data) =>
        @scope.error = true
        @scope.errorMessage = data.detail

    onSuccess: (user) =>
        if @routeParams and @routeParams['next'] and @routeParams['next'] != '/login'
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
        @scope.errorMessage = ''

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

        setTimeout(=>
            @.location.url("/login")
            @.scope.$apply()
        , 2000)


class ChangePasswordController extends TaigaPageController
    @.$inject = ['$scope', '$rootScope', '$location', '$routeParams',
                 'resource', '$i18next', '$favico']
    constructor: (@scope, @rootScope, @location, @routeParams, @rs, @i18next, @favico) ->
        super(scope, rootScope, favico)

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

            setTimeout(=>
                @location.url("/login")
                @scope.$apply()
            , 2000)

        promise.then null, (data) =>
            @scope.error = true
            @scope.success = false
            @scope.formData = {}
            @scope.errorMessage = data.detail

        return promise


class ProfileController extends TaigaPageController
    #TODO:  Hi, I'm the controller class for the user profile form and u have to
    #       write me from scratch after the UX refactor, please, please!!!

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
        @scope.authForm = @scope.auth       # NOTE: WTF!!

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

        return promise


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
        @scope.$watch "site.data.public_register", (value) =>
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

        return promise


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

        return promise

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
