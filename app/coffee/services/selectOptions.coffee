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


class SelectOptionsService extends TaigaBaseService
    @.$inject = ["$rootScope"]

    constructor: (@rootScope) ->
        super()

    colorizedTags: (option, container) ->
        hash = hex_sha1(option.text.trim().toLowerCase())
        color = hash
            .substring(0,6)
            .replace("8","0")
            .replace("9","1")
            .replace("a","2")
            .replace("b","3")
            .replace("c","4")
            .replace("d","5")
            .replace("e","6")
            .replace("f","7")

        container.parent().css("background", "##{color}")
        container.text(option.text)
        return

    member: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: Make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
        return "<span>#{option.text}</span>"

module = angular.module("taiga.services.selectOptions", [])
module.service("selectOptions", SelectOptionsService)
