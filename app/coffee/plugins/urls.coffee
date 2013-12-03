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

UrlsProvider = ->
    data = {
        urls: {}
        host: {}
        scheme: {}
    }

    setHost = (ns, host, scheme) ->
        data.host[ns] = host
        data.scheme[ns] = scheme

    setUrls = (ns, urls) ->
        if _.toArray(arguments).length != 2
            throw Error("wrong arguments to setUrls")

        data.urls[ns] = urls
        service[ns] = ->
            if _.toArray(arguments).length < 1
                throw Error("wrong arguments")

            args = _.toArray(arguments)
            name = args.slice(0, 1)[0]
            url = format(data.urls[ns][name], args.slice(1))

            if data.host[ns]
                return format("%s://%s%s", [data.scheme[ns], data.host[ns], url])

            return url

    service = {}
    service.data = data
    service.setUrls = setUrls
    service.setHost = setHost

    @.setUrls = setUrls
    @.setHost = setHost

    @.$get = ->
        return service

    return

module = angular.module("gmUrls", [])
module.provider('$gmUrls', UrlsProvider)
