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


class FlashMessagesService extends TaigaBaseService
    @.$inject = ['$rootScope']
    constructor: (@rootScope) ->
        super()

    info: (message) ->
        @rootScope.$broadcast("flash:new", true, message)

    error: (message) ->
        @rootScope.$broadcast("flash:new", false, message)


FlashMessagesDirective = ->
    compile: (element, attrs) ->
        template = """
        <div class="flash-message-success hidden"><p class="msg"></p></div>
        <div class="flash-message-fail hidden"><p class="msg"></p></div>
        """
        element.html(template)
        return @.link

    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        scope.$on "flash:new", (ctx, success, message) ->
            if success
                element.find(".flash-message-success p").text(message)
                element.find(".flash-message-success").fadeIn().delay(2000).fadeOut()
            else
                element.find(".flash-message-fail p").text(message)
                element.find(".flash-message-fail").fadeIn().delay(2000).fadeOut()


module = angular.module('gmFlash', [])
module.service('$gmFlash', FlashMessagesService)
module.directive('gmFlashMessages', FlashMessagesDirective)
