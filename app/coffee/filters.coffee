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
        if input
            return moment(input).format(format)
        else
            return ""

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
        return if input then input.charAt(0).toUpperCase() + input.slice(1).toLowerCase() else ""

SizeFormatFilter = ->
    return (input, precision) ->
        if isNaN(parseFloat(input)) or !isFinite(input)
            return '-'

        if input == 0
            return '0 bytes'

        if precision == undefined
            precision = 1

        units = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB']
        number = Math.floor(Math.log(input) / Math.log(1024))
        if number > 5
            number = 5
        size = (input / Math.pow(1024, number)).toFixed(precision)
        return  "#{size} #{units[number]}"

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
module.filter("diff", ['$sce', DiffFilter])
