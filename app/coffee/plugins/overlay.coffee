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


class OverlayService extends TaigaBaseService
    @.$inject = ["$rootScope", "$q", "$log"]
    constructor: (@rootScope, @q, @log) ->
        super()

    close: ->
        @log.debug "OverlayService.close"
        @.el.off()
        @.el.remove()

    open: ->
        @log.debug "OverlayService.open"

        @.defered = @q.defer()

        if angular.element(".overlay").length == 0
            @.el = angular.element("<div />", {"class": "overlay"})

            body = angular.element("body")
            body.append(@.el)
        else
            @.el = angular.element(".overlay")

        @.el.on "click", (event) =>
            @rootScope.$apply =>
                @.close()
                @.defered.resolve()
        return @.defered.promise


module = angular.module("gmOverlay", [])
module.service('$gmOverlay', OverlayService)
