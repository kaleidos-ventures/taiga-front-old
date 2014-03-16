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


class AuthService extends TaigaBaseService
    constructor: (@rootScope, @gmStorage, @model) ->
        super()

    getUser: ->
        userData = @gmStorage.get('userInfo')
        if userData
            return @model.make_model("users", userData)
        return null

    setUser: (user) ->
        @rootScope.auth = user
        @rootScope.$broadcast('i18n:change', user.default_language)
        @gmStorage.set("userInfo", user.getAttrs())

    unsetUser: ->
        @rootScope.auth = null
        @gmStorage.remove("userInfo")

    setToken: (token) ->
        @gmStorage.set("token", token)

    getToken: ->
        @gmStorage.get("token")

    setSessionId: (sessionId) ->
        @.sessionId = sessionId

    getSessionId: ->
        return @.sessionId

    isAuthenticated: ->
        if @.getUser() != null
            return true
        return false


class AuthProvider
    initialize: (sessionId) ->
        @.sessionId = sessionId

    $get: ($rootScope, $gmStorage, $model) ->
        service = new AuthService($rootScope, $gmStorage, $model)
        service.setSessionId(@.sessionId)

        return service

    @.prototype.$get.$inject = ["$rootScope", "$gmStorage", "$model"]

module = angular.module('taiga.services.auth', [])
module.provider("$gmAuth", AuthProvider)
