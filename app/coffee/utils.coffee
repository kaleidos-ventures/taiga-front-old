utils = @gm.utils = {}

utils.pointIdToOrder = (points, roles) ->
    return (us_points) ->
        total = 0

        for key, value of us_points
            if points[value].value != null
                total += points[value].value
        return total
