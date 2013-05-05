angular.module 'greenmine.services.model', [], ($provide) ->
    modelProvider = ($q, $http, url, storage) ->
        headers = ->
            return {"X-SESSION-TOKEN": storage.get('token')}

        class Model
            constructor: (name, data) ->
                @_attrs = data
                @_name = name

                @_isModified = false
                @_modifiedAttrs = {}

                @initialize()

            getUrl: ->
                return "#{url(@_name)}#{@_attrs.id}/"

            initialize: () ->
                self = @

                getter = (name) ->
                    return ->
                        if name.substr(0,2) == "__"
                            return self[name]

                        if self._modifiedAttrs[name] is not undefined
                            return self._modifiedAttrs[name]
                        else
                            return self._attrs[name]

                setter = (name) ->
                    return (value) ->
                        if name.substr(0,2) == "__"
                            self[name] = value
                        else if self._attrs[name] != value
                            self._modifiedAttrs[name] = value
                            self._isModified = true

                _.each @_attrs, (value, name) ->
                    options =
                        get: getter(name)
                        enumerable: true
                        configurable: true

                    if name != "id"
                        options.set = setter(name)

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

                params =
                    method: "DELETE"
                    url: @getUrl()
                    headers: headers()

                promise = $http(params)
                promise.success (data, status) ->
                    defered.resolve(data, status)

                promise.error(data, status) ->
                    defered.reject(data, status)

                return defered.promise

            save: () ->
                self = @
                defered = $q.defer()

                if @isModified()
                    defered.resolve(true)
                    return defered.promise

                postObject = _.extend({}, @_modifiedAttrs)

                params =
                    method: "PATCH"
                    url: @getUrl()
                    headers: headers(),
                    data: JSON.stringify(postObject)

                promise = $http(params)
                promise.success (data, status) ->
                    self._isModified = false
                    self._attrs = _.extend(self._attrs, self._modifiedAttrs, data)
                    self._modifiedAttrs = {}
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

                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject([data, status])

                return defered.promise

            @desSerialize = (sdata) ->
                ddata = JSON.parse(sdata)
                model = new Model(ddata.url, ddata.data)
                return model

        service = (name, data, cls=Model) -> new cls(name, data)
        service.cls = Model

        return service

    $provide.factory('$model', ['$q', '$http', 'url', 'storage', modelProvider])
