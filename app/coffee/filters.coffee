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

module = angular.module('greenmine.filters', [])
module.filter("lowercase", LowercaseFilter)
module.filter("momentFormat", MomentFormatFilter)
module.filter("slugify", SlugifyFilter)
module.filter("truncate", TruncateFilter)
module.filter("onlyVisible", OnlyVisibleFilter)
