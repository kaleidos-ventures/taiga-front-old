"use strict";

(function() {
    var utils = this.greenmine.utils = {};

    utils.pointIdToOrder = function(scope) {
        return function(id) {
            var point = scope.constants.points[id];
            if (point.order === -2) {
                return 0.5;
            } else if (point.order === -1) {
                return 0;
            } else {
                return point.order;
            }
        };
    };
}).call(this);
