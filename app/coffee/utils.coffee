utils = @greenmine.utils = {}

utils.pointIdToOrder = (points) ->
    return (id) ->
        point = points[id]
        if point.order == -2
            return 0.5
        else if point.order == -1
            return 0
        else
            return point.order
