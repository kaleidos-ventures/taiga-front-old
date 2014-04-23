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


format = (fmt, obj) ->
    obj = _.clone(obj)
    return fmt.replace /%s/g, (match) -> String(obj.shift())

class UrlsService
    constructor: (data) ->
        @data = data

    setHost: (ns, host, scheme) ->
        if _.toArray(arguments).length != 3
            throw Error("wrong arguments to setHost")

        @data.host[ns] = host
        @data.scheme[ns] = scheme


class UrlsProvider
    data: {
        urls: {}
        host: {}
        scheme: {}
    }

    setUrls: (ns, urls) ->
        if _.toArray(arguments).length != 2
            throw Error("wrong arguments to setUrls")

        @data.urls[ns] = urls
        UrlsService.prototype[ns] = ->
            if _.toArray(arguments).length < 1
                throw Error("wrong arguments")

            args = _.toArray(arguments)
            name = args.slice(0, 1)[0]
            url = format(@data.urls[ns][name], args.slice(1))

            if @data.host[ns]
                return format("%s://%s%s", [@data.scheme[ns], @data.host[ns], url])

            return url

    $get: ->
        return new UrlsService(@data)

module = angular.module("gmUrls", [])
module.provider('$gmUrls', UrlsProvider)
