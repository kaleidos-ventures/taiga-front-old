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

angular.module 'greenmine.services.model', [], ($provide) ->
    modelProvider = ($q, $http, url, storage) ->
        headers = ->
            return {"X-SESSION-TOKEN": storage.get('token')}

        class Model
            constructor: (name, data, dataTypes) ->
                @_attrs = data
                @_name = name
                @_dataTypes = dataTypes

                @_isModified = false
                @_modifiedAttrs = {}

                @initialize()
                @applyCasts()

            applyCasts: ->
                for attrName, castName of @_dataTypes
                    castMethod = service.casts[castName]
                    if not castMethod
                        continue

                    @_attrs[attrName] = castMethod(@_attrs[attrName])


            getIdAttrName: ->
                return "id"

            getUrl: ->
                return "#{url(@_name)}/#{@getAttrs()[@getIdAttrName()]}"

            getAttrs: (patch=false) ->
                if patch
                    return _.extend({}, @_modifiedAttrs)

                return _.extend({}, @_attrs, @_modifiedAttrs)

            initialize: () ->
                self = @

                getter = (name) ->
                    return ->
                        if name.substr(0,2) == "__"
                            return self[name]

                        if name not in _.keys(self._modifiedAttrs)
                            return self._attrs[name]

                        return self._modifiedAttrs[name]

                setter = (name) ->
                    return (value) ->
                        if name.substr(0,2) == "__"
                            self[name] = value
                            return

                        if self._attrs[name] != value
                            self._modifiedAttrs[name] = value
                            self._isModified = true
                        else
                            delete self._modifiedAttrs[name]

                        return

                _.each @_attrs, (value, name) ->
                    options =
                        get: getter(name)
                        set: setter(name)
                        enumerable: true
                        configurable: true

                    Object.defineProperty(self, name, options)

            serialize: () ->
                data =
                    "data": _.clone(@_attrs)
                    "name": @_name

                return JSON.stringify(data)

            isModified: () ->
                return this._isModified

            revert: () ->
                @_modifiedAttrs = {}
                @_isModified = false

            remove: () ->
                defered = $q.defer()
                self = @

                params =
                    method: "DELETE"
                    url: @getUrl()
                    headers: headers()

                promise = $http(params)
                promise.success (data, status) ->
                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject(self)

                return defered.promise

            save: (patch=true) ->
                self = @
                defered = $q.defer()

                if not @isModified() and patch
                    defered.resolve(self)
                    return defered.promise

                params =
                    url: @getUrl()
                    headers: headers(),

                if patch
                    params.method = "PATCH"
                else
                    params.method = "PUT"

                params.data = JSON.stringify(@getAttrs(patch))

                promise = $http(params)
                promise.success (data, status) ->
                    self._isModified = false
                    self._attrs = _.extend(self.getAttrs(), data)
                    self._modifiedAttrs = {}

                    self.applyCasts()
                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject()

                return defered.promise

            refresh: () ->
                defered = $q.defer()
                self = @

                params =
                    method: "GET",
                    url: @getUrl()
                    headers: headers()

                promise = $http(params)
                promise.success (data, status) ->
                    self._modifiedAttrs = {}
                    self._attrs = data
                    self._isModified = false
                    self.applyCasts()

                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject([data, status])

                return defered.promise

            @desSerialize = (sdata) ->
                ddata = JSON.parse(sdata)
                model = new Model(ddata.url, ddata.data)
                return model

        service = {}
        service.make_model = (name, data, cls=Model, dataTypes={}) ->
            return new cls(name, data, dataTypes)

        service.create = (name, data, cls=Model, dataTypes={}) ->
            defered = $q.defer()

            params =
                method: "POST"
                url: url(name)
                headers: headers()
                data: JSON.stringify(data)

            promise = $http(params)
            promise.success (_data, _status) ->
                defered.resolve(service.make_model(name, _data, cls, dataTypes))

            promise.error (data, status) ->
                defered.reject(null)

            return defered.promise

        service.cls = Model
        service.casts =
            int: (value) ->
                return parseInt(value, 10)

            float: (value) ->
                return parseFloat(value, 10)

        return service

    $provide.factory('$model', ['$q', '$http', 'url', 'storage', modelProvider])
