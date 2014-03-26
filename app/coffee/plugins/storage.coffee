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

class StorageService extends TaigaBaseService
    @.$inject = ["$rootScope"]
    constructor: ($rootScope) ->
        super()

    get: (key, _default) ->
        serializedValue = localStorage.getItem(key)
        if serializedValue == null
            return _default or null

        return JSON.parse(serializedValue)

    set: (key, val) ->
        if _.isObject(key)
            _.each key, (val, key) =>
                @set(key, val)
        else
            localStorage.setItem(key, JSON.stringify(val))

    contains: (key) ->
        value = @.get(key)
        return (value != null)

    remove: (key) ->
        localStorage.removeItem(key)

    clear: ->
        localStorage.clear()


module = angular.module('gmStorage', [])
module.service('$gmStorage', StorageService)
