utils = @greenmine.utils = {}

utils.pointIdToOrder = (points, roles) ->
    return (us_points) ->
        return _.reduce(_.map(us_points, (value, key) -> points[value].value), (acum, elem) -> elem+acum)
