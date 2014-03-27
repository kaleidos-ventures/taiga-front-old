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
