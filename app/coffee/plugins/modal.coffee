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

ModalServiceFactory = ($rootScope, $q, $log) ->
    modals = {}
    service = {}

    service.register = (name, domId) ->
        $log.debug "registering modal: #{name}"
        modals[name] = domId

    service.open = (name, ctx) ->
        dom = angular.element("##{modals[name]}")
        $(dom.find('.modal')).css('top': $(document).scrollTop() + 15)

        defered = $q.defer()

        ctrl = dom.controller()
        scp = dom.scope()
        ctrl.initialize(defered, ctx)
        return defered.promise

    service.close = (name) ->
        dom = angular.element("##{modals[name]}")

        ctrl = dom.controller()
        ctrl.delete()

    return service


ModalRegisterDirective = ($rootScope, $modal) ->
    return (scope, element, attrs) ->
        name = attrs.gmModal
        domId = _.uniqueId("gm-modal-")

        element.attr("id", domId)
        $modal.register(name, domId)


module = angular.module("gmModal", [])
module.factory("$modal", ["$rootScope", "$q", "$log", ModalServiceFactory])
module.directive("gmModal", ["$rootScope", "$modal", ModalRegisterDirective])
