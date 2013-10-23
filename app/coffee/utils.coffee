utils = @gm.utils = {}

utils.delay = (timeout, func) ->
    return _.delay(func, timeout)

utils.defer = (func) ->
    return _.defer(func)

utils.debounced = (timeout, func) ->
    return _.debounce(func, timeout)
