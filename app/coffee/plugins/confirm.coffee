# Copyright 2013 Andrey Antukh <niwi@niwi.be>
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

class SimpleConfirmService extends TaigaBaseService
    @.$inject = ["$rootScope", "$q", "$window"]
    constructor: (@rootScope, @q, @window) ->
        super()

    confirm: (message) ->
        defered = @q.defer()

        _.defer ->
            res = @window.confirm(message)
            if res
                defered.resolve()
            else
                defered.reject()
            @rootScope.$apply()

        return defered.promise


module = angular.module('gmConfirm', [])
module.service('$confirm', SimpleConfirmService])
