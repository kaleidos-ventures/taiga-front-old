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

I18NextDirective = ($parse, $rootScope) ->
    restrict: "A"
    link: (scope, elm, attrs) ->
        t = $rootScope.translate

        evaluateTranslation = ->
            element = angular.element(elm)
            for value in attrs.i18next.split(",")
                if value.indexOf(":") == -1
                    element.html(t(value))
                else
                    [ns, value] = value.split(":")
                    element.attr(ns, t(value))

        evaluateTranslation()
        $rootScope.$on "i18next:changeLang", ->
            evaluateTranslation()

I18NextProvider = ($rootScope, storage, $q) ->
    i18n.addPostProcessor "lodashTemplate", (value, key, options) ->
        template = _.template(value)
        return template(options.scope)

    options =
        postProcess: "lodashTemplate",
        fallbackLng: "en",
        useLocalStorage: false,
        localStorageExpirationTime: 60*60*24*1000, # 1 day
        resGetPath: 'locales/__lng__/__ns__.json',
        ns: 'app'

    service = {}

    service.setLang = (lang) ->
        $rootScope.currentLang = lang
        storage.set("lang", lang)

        i18n.setLng lang, (t) ->
            $rootScope.$broadcast("i18next:changeLang")

    service.getCurrentLang = ->
        return $rootScope.currentLang

    service.translate = (key, options)->
        return $rootScope.t(key, options)

    service.t = service.translate

    service.initialize = ->
        defer = $q.defer()

        # Put to rootScope a initial values
        $rootScope.currentLang = storage.get("lang", "en")

        options['lng'] = $rootScope.currentLang

        i18n.init options, (t) ->
            # Put translate function to a rootScope
            $rootScope.$apply ->
                $rootScope.translate = t
                $rootScope.t = t
                defer.resolve(t)
                $rootScope.$broadcast("i18next:loadComplete", t)
            return defer.promise

    service.sync_initialize = ->
        # Put to rootScope a initial values
        $rootScope.currentLang = storage.get("lang", "en")

        options['lng'] = $rootScope.currentLang

        i18n.init options
        $rootScope.t = i18n.t
        $rootScope.translate = i18n.t
        $rootScope.$broadcast("i18next:loadComplete", i18n.t)
        return i18n.t

    return service


I18NextTranslateFilter = ($i18next) ->
    return (key, options) ->
        return $i18next.t(key, options)

module = angular.module('i18next', [])
module.factory("$i18next", ['$rootScope', '$gmStorage', '$q', I18NextProvider])
module.directive('i18next', ['$parse', '$rootScope', I18NextDirective])
module.filter('i18next', ['$i18next', I18NextTranslateFilter])
