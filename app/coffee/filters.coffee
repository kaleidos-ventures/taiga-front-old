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

LowercaseFilter = ->
    return (input) ->
        return if input then input.toLowerCase() else ""

SizeFormatFilter = ->
    return (input, precision) ->
        if isNaN(parseFloat(input)) or !isFinite(input)
            return '-'
        if precision == 'undefined'
            precision = 1

        units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB']
        number = Math.floor(Math.log(input) / Math.log(1024))

        return (input / Math.pow(1024, Math.floor(number))).toFixed(precision) +  ' ' +
               units[number]


module = angular.module('greenmine.filters', [])
module.filter("lowercase", LowercaseFilter)
module.filter("momentFormat", MomentFormatFilter)
module.filter("slugify", SlugifyFilter)
module.filter("truncate", TruncateFilter)
module.filter("onlyVisible", OnlyVisibleFilter)
module.filter("sizeFormat", SizeFormatFilter)
