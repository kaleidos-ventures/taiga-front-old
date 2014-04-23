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


class FavicoService extends TaigaBaseService
    _defaultOptions: {
        bgColor: "#d00"             # Hex background color
        textColor: "#fff"           # Hex text color
        fontFamily: "sans-serif"    # [Arial, Verdana, Times New Roman, serif, sans-serif,...]
        fontStyle: "bold"           # [normal, italic, oblique, bold, bolder, lighter, 100, 200, 300, ... 900]
        type: "circle"              # [circle, rectangle]
        position: "down"            # [up, down, left, upleft]
        animation: "popFade"          # [slide, fade, pop, popFade, none]
    }

    constructor: ->
        @_favico = null

    newFavico: (opts) ->
        try
            if @_favico is null
                opts = opts or @_defaultOptions
                @_favico = new Favico(opts)
        catch err
            false

    badge: (num) ->
        @_favico?.badge(num)

    reset: () ->
        try
            @_favico.reset()
        catch err
            true # ignore

    destroy: () ->
        @_favico = null


module = angular.module('favico', [])
module.service('$favico', FavicoService)
