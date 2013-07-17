utils = @greenmine.utils = {}

utils.pointIdToOrder = (points, roles) ->
    return (us_points) ->
        total = 0
        _.each us_points, (value, key) ->
            if points[key].value?
                total = total + points[key].value

        console.log total
        return total
