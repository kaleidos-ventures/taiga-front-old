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
