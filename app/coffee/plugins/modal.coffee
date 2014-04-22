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


class ModalService extends TaigaBaseService
    @.$inject = ["$q", "$log"]
    constructor: (@q, @log) ->
        super()

    modals: {}

    register: (name, domId) ->
        @log.debug "registering modal: #{name}"
        @modals[name] = domId

    open: (name, ctx) ->
        dom = angular.element("##{@modals[name]}")
        $(dom.find('.modal')).css('top': $(document).scrollTop() + 15)

        defered = @q.defer()

        ctrl = dom.controller()
        scp = dom.scope()
        ctrl.start(defered, ctx)
        return defered.promise

    close: (name) ->
        dom = angular.element("##{@modals[name]}")

        ctrl = dom.controller()
        ctrl.delete()


ModalRegisterDirective = ($rootScope, $modal) ->
    return (scope, element, attrs) ->
        name = attrs.gmModal
        domId = _.uniqueId("gm-modal-")

        element.attr("id", domId)
        $modal.register(name, domId)


module = angular.module("gmModal", [])
module.service("$modal", ModalService)
module.directive("gmModal", ["$rootScope", "$modal", ModalRegisterDirective])
