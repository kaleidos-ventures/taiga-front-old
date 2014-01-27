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


OnlyVisibleFilter = ->
    return (input) ->
        return _.filter input, (item) ->
            return item.__hidden != true

TruncateFilter = ->
    return (input, num) ->
        num = 25 if num is undefined
        return _.str.prune(input, num)

SlugifyFilter = ->
    return (input) ->
        return _.str.slugify(input)

MomentFormatFilter = ->
    return (input, format) ->
        return moment(input).format(format)

MomentFromNowFilter = ->
    return (input, without_suffix) ->
        if input
            return moment(input).fromNow(without_suffix or false)
        else
            return ""

LowercaseFilter = ->
    return (input) ->
        return if input then input.toLowerCase() else ""

CapitalizeFilter = ->
    return (input) ->
        return if input then input.charAt(0).toUpperCase() + input.slice(1) else ""

SizeFormatFilter = ->
    return (input, precision) ->
        if isNaN(parseFloat(input)) or !isFinite(input)
            return '-'

        if input == 0
            return '0 bytes'

        if precision == 'undefined'
            precision = 1

        units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB']
        number = Math.floor(Math.log(input) / Math.log(1024))
        return (input / Math.pow(1024, Math.floor(number))).toFixed(precision) +  ' ' +
               units[number]

DiffFilter = ($sce) ->
    return (newText, oldText, semantic=true, efficiency=false) ->
        newText = newText or ""
        oldText = oldText or ""

        dmp = new diff_match_patch()

        d = dmp.diff_main(oldText, newText)
        if semantic
            dmp.diff_cleanupSemantic(d)
        if efficiency
            dmp.diff_cleanupEfficiency(d)

        html_diff = dmp.diff_prettyHtml(d)

        return $sce.trustAsHtml(html_diff)

module = angular.module('taiga.filters', [])
module.filter("lowercase", LowercaseFilter)
module.filter("capitalize", CapitalizeFilter)
module.filter("momentFormat", MomentFormatFilter)
module.filter("momentFromNow", MomentFromNowFilter)
module.filter("slugify", SlugifyFilter)
module.filter("truncate", TruncateFilter)
module.filter("onlyVisible", OnlyVisibleFilter)
module.filter("sizeFormat", SizeFormatFilter)
module.filter("diff", DiffFilter)
