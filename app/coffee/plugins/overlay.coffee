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

OverlayProvider = ($rootScope, $q, $log) ->
    class OverlayService
        constructor: ->
            @.el = angular.element("<div />", {"class": "overlay"})
            @.defered = $q.defer()

            _.bindAll(@)

        close: ->
            $log.debug "OverlayService.close"
            @.el.off()
            @.el.remove()

        open: ->
            $log.debug "OverlayService.open"
            self = @

            @.el.on "click", (event) ->
                $rootScope.$apply ->
                    self.close()
                    self.defered.resolve()

            body = angular.element("body")
            body.append(@.el)

            return @.defered.promise

    return -> new OverlayService()


module = angular.module("gmOverlay", [])
module.factory('$gmOverlay', ["$rootScope", "$q", "$log", OverlayProvider])
