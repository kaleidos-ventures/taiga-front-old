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

FlashMessagesProvider = ($rootScope, $q, $window) ->
    service = {}
    service.info = (message, scrollUp) ->
        $rootScope.$broadcast("flash:new", true, message, scrollUp)

    service.error = (message, scrollUp) ->
        $rootScope.$broadcast("flash:new", false, message, scrollUp)

    return service


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
        scope.$on "flash:new", (ctx, success, message, scrollUp) ->
            if success
                element.find(".flash-message-success p").text(message)
                element.find(".flash-message-success").fadeIn().delay(2000).fadeOut()
            else
                element.find(".flash-message-fail p").text(message)
                element.find(".flash-message-fail").fadeIn().delay(2000).fadeOut()

            if not scrollUp?
                scrollUp = true

            if scrollUp
                angular.element("html, body").animate({ scrollTop: 0 }, "slow")


module = angular.module('gmFlash', [])
module.factory('$gmFlash', ["$rootScope", "$q", "$window", FlashMessagesProvider])
module.directive('gmFlashMessages', FlashMessagesDirective)
