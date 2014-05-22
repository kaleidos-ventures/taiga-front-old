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

defaultOptions = {
    ns: "app"
    fallbackLng: "en"
    async: false
}

class I18NextService extends TaigaBaseService
    @.$inject = ["$rootScope", "$q", "locales.en", "locales.es"]

    constructor: (@rootScope, @q, @localeEn, @localeEs) ->
        i18n.addPostProcessor "lodashTemplate", (value, key, options) ->
            template = _.template(value)
            return template(options.scope)
        @t = @translate

    setLang: (lang) ->
        @rootScope.currentLang = lang
        options = _.clone(@._defaultOptions, true)
        i18n.setLng lang, options, =>
            @rootScope.$broadcast("i18next:changeLang")

    getCurrentLang: ->
        return @rootScope.currentLang

    translate: (key, options)->
        return i18n.t(key, options)

    initialize: (defaultLang="en") ->
        # Put to rootScope a initial values
        options = _.clone(defaultOptions, true)
        options.lng = @rootScope.currentLang = defaultLang
        options.resStore = {
            en: { app: @localeEn }
            es: { app: @localeEs }
        }

        i18n.init(options)
        @rootScope.translate = i18n.t
        @rootScope.t = i18n.t
        @rootScope.$broadcast("i18next:loadComplete", i18n.t)


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


I18NextTranslateFilter = ($i18next) ->
    return (key, options) ->
        return $i18next.t(key, options)


module = angular.module('i18next', ["locales.es", "locales.en"])
module.service("$i18next", I18NextService)
module.directive('i18next', ['$parse', '$rootScope', I18NextDirective])
module.filter('i18next', ['$i18next', I18NextTranslateFilter])
