angular.module('greenmine.filters.common', []).
    filter('onlyVisible', ->
        return (input) ->
            return _.filter input, (item) ->
                return item.__hidden != true
    ).
    filter('truncate', ->
        return (input, num) ->
            num = 25 if num == undefined
            return _.str.prune(input, num)
    ).
    filter('slugify', ->
        return (input) ->
            return _.str.slugify(input)
    ).
    filter("momentFormat", ->
        return (input, format) ->
            return moment(input).format(format)
    ).
    filter("lowercase", ->
        return (input) ->
            if input
                return input.toLowerCase()
            return ""
    )
