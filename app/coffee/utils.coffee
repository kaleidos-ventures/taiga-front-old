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


gm = @.gm
utils = @.gm.utils = {}

utils.delay = (timeout, func) ->
    return _.delay(func, timeout)

utils.defer = (func) ->
    return _.defer(func)

utils.defered = (func) ->
    return ->
        utils.defer(func)

utils.debounced = (timeout, func) ->
    return _.debounce(func, timeout)

utils.truncate = (data, length) ->
    return _.str.truncate(data, length)

gm.safeApply = (scope, fn) ->
    if (scope.$$phase || scope.$root.$$phase)
        fn()
    else
        scope.$apply(fn)

gm.format = (fmt, obj, named) ->
    obj = _.clone(obj)
    if named
        return fmt.replace /%\(\w+\)s/g, (match) -> String(obj[match.slice(2,-2)])
    else
        return fmt.replace /%s/g, (match) -> String(obj.shift())

# Function that return debounced function
# but wrapping in safe $digest process.
utils.safeDebounced = (scope, timeout, func) ->
    wrapper = ->
        gm.safeApply(scope, func)
    utils.debounced(timeout, wrapper)
