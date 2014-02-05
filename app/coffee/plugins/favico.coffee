# Copyright 2014 David Barragán <bameda@dbarragan.com>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


FavicoProvider = () ->
    service = {}

    defaultOptions = {
        bgColor: "#d00"             # Hex background color
        textColor: "#fff"           # Hex text color
        fontFamily: "sans-serif"    # [Arial, Verdana, Times New Roman, serif, sans-serif,...]
        fontStyle: "bold"           # [normal, italic, oblique, bold, bolder, lighter, 100, 200, 300, ... 900]
        type: "circle"              # [circle, rectangle]
        position: "down"            # [up, down, left, upleft]
        animation: "popFade"          # [slide, fade, pop, popFade, none]
    }

    service.newFavico = (opts=defaultOptions) ->
        service._favico = new Favico(opts)

    service.badge = (num) ->
        service._favico.badge(num)

    service.reset = () ->
        service._favico.reset()

    service.destroy = () ->
        service._favico = null

    return service


module = angular.module('favico', [])
module.factory('$favico', [FavicoProvider])
