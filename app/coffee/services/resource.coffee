angular.module('greenmine.services.resource', ['greenmine.config'], ($provide) ->
    urlProvider = (config) ->
        urls =
            "auth": "/api/auth/login/"
            "users": "/api/users/"
            "projects": "/api/scrum/projects/"
            "userstories": "/api/scrum/user-stories/"
            "milestones": "/api/scrum/milestones/"
            "tasks": "/api/scrum/tasks/"
            "issues": "/api/scrum/issues/"
            "issues/attachments": "/api/scrum/issues/attachments/"
            "wikipages": "/api/wiki/pages/"
            "choices/task-status": "/api/scrum/tasks/statuses/"
            "choices/issue-status": "/api/scrum/issues/statuses/"
            "choices/issue-types": "/api/scrum/issues/types/"
            "choices/us-status": "/api/scrum/user-stories/statuses/"
            "choices/points": "/api/scrum/user-stories/points/"
            "choices/priorities": "/api/scrum/priorities/"
            "choices/severities": "/api/scrum/severities/"

        host = config.host
        scheme=config.scheme

        return () ->
            args = _.toArray(arguments)
            name = args.slice(0, 1)
            params = [urls[name]]

            for item in args.slice(1)
                params.push(item)

            url = _.str.sprintf.apply(null, params)
            return _.str.sprintf("%s://%s%s", scheme, host, url)

    resourceProvider = ($http, $q, storage, url, config) ->
        service = {}

        headers = ->
            return {"X-SESSION-TOKEN": storage.get('token')}

        toJson = (data) ->
            return JSON.stringify(data)

        interpolate = (fmt, obj, named) ->
            if named
                return fmt.replace(/%\(\w+\)s/g, (match) -> String(obj[match.slice(2,-2)]))
            else
                return fmt.replace(/%s/g, (match) -> String(obj.shift()))


        class Model
            constructor: (data, url) ->
                @_attrs = data
                @_url = url

                @_isModified = false
                @_modifiedAttrs = {}

                @initialize()

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
                    "url": @_url

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
                    url: @_url
                    headers: headers()

                $http(params).success((data, status) ->
                    defered.resolve(data, status)
                ).error((data, status) ->
                    defered.reject(data, status)
                )
                return defered.promise

            save: () ->
                self = @
                defered = $q.defer()

                if @isModified()
                    defered.resolve(true)
                else
                    postObject = _.extend({}, @_modifiedAttrs)

                    params =
                        method: "PATCH"
                        url: @_url
                        headers: headers(),
                        data: toJson(postObject)

                    $http(params).success((data, status) ->
                        self._isModified = false
                        self._attrs = _.extend(self._attrs, self._modifiedAttrs, data)
                        self._modifiedAttrs = {}
                        defered.resolve(self)
                    ).error((data, status) ->
                        defered.reject([self, data, status])
                    )

                return defered.promise

            refresh: () ->
                defered = $q.defer()
                self = @

                params =
                    method: "GET",
                    url: @_url
                    headers: headers()

                $http(params).success((data, status) ->
                    self._modifiedAttrs = {}
                    self._attrs = data
                    self._isModified = false

                    defered.resolve(self)
                ).error((data, status) ->
                    defered.reject([data, status])
                )

                return defered.promise

        Model.desSerialize = (sdata) ->
            ddata = JSON.parse(sdata)
            model = new Model(ddata.url, ddata.data)
            return model

        # Resource Action Helpers
        itemUrlTemplate = "%(url)s%(id)s/"

        queryMany = (url, params, options) ->
            defauts = {method: "GET", headers:  headers()}
            current = {url: url, params: params or {}}

            httpParams = _.extend({}, defauts, options, current)
            defered = $q.defer()

            $http(httpParams).success((data, status) ->
                models = _.map data, (item) ->
                    modelurl = interpolate(itemUrlTemplate, {"url": url, "id": item.id}, true)
                    return new Model(item, modelurl)

                defered.resolve(models)
            ).error((data, status) ->
                defered.reject(data, status)
            )

            return defered.promise

        queryOne = (url, params) ->
            paramsDefault = {"method":"GET", "headers": headers(), "url": url}
            defered = $q.defer()

            params = _.extend({}, paramsDefault, params or {})

            $http(params).success((data, status) ->
                model = new Model(data, url)
                defered.resolve(model)
            ).error((data, status) ->
                defered.reject([data, status])
            )

            return defered.promise


        # Resource Methods

        # Login request
        service.login = (username, password) ->
            defered = $q.defer()

            onSuccess = (data, status) ->
                storage.set("token", data["token"])
                defered.resolve(data)

            onError = (data, status) ->
                defered.reject(data)

            postData =
                "username": username
                "password":password

            $http({method:'POST', url: url('auth'), data: toJson(postData)})
                .success(onSuccess).error(onError)

            return defered.promise

        # Get a project list
        service.getProjects = -> queryMany(url('projects'))

        # Get available task statuses for a project.
        service.getTaskStatuses = (projectId) ->
            return queryMany(url('choices/task-status'), {project: projectId})

        service.getUsPoints = (projectId) ->
            return queryMany(url('choices/points'), {project: projectId})

        service.getPriorities = (projectId) ->
            return queryMany(url("choices/priorities"), {project: projectId})

        service.getSeverities = (projectId) ->
            return queryMany(url("choices/severities"), {project: projectId})

        service.getIssueStatuses = (projectId) ->
            return queryMany(url("choices/issue-status"), {project: projectId})

        service.getIssueTypes = (projectId) ->
            return queryMany(url("choices/issue-types"), {project: projectId})

        service.getUsStatuses = (projectId) ->
            return queryMany(url("choices/us-status"), {project: projectId})

        # Get a milestone lines for a project.
        service.getMilestones = (projectId) ->
            # First step: obtain data
            _getMilestones = ->
                defered = $q.defer()

                params =
                    "method":"GET"
                    "headers": headers()
                    "url": url("milestones")
                    "params": {"project": projectId}

                $http(params).success((data, status) ->
                    defered.resolve(data)
                ).error((data, status) ->
                    defered.reject(data, status)
                )

                return defered.promise

            # Second step: make user story models
            _makeUserStoryModels = (objects) ->
                baseUrl = url("userstories")

                for milestone in objects
                    user_stories = _.map milestone.user_stories, (item) ->
                        modelurl = interpolate(itemUrlTemplate, {"url": baseUrl, "id": item.id}, true)
                        return new Model(item, modelurl)

                    milestone.user_stories = user_stories

                return objects

            # Third step: make milestone models
            _makeModels = (objects) ->
                baseUrl = url("milestones")

                return _.map objects, (item) ->
                    modelurl = interpolate(itemUrlTemplate, {"url": baseUrl, "id": item.id}, true)
                    return new Model(item, modelurl)

            return _getMilestones().then(_makeUserStoryModels).then(_makeModels)

        # Get unassigned user stories list for a project.
        service.getUnassignedUserStories = (projectId) ->
            return queryMany(url("userstories"),
                {"project":projectId, "milestone": "null"})

        # Get a user stories list by projectId and sprintId.
        service.getMilestoneUserStories = (projectId, sprintId) ->
            return queryMany(url("userstories"),
                {"project":projectId, "milestone": sprintId})

        service.getTasks = (projectId, sprintId) ->
            params = {project:projectId}
            if sprintId != undefined
                params.milestone = sprintId

            return queryMany(url("tasks"), params)

        # Get project Issues list
        service.getIssues = (projectId) ->
            return queryMany(url("issues"), {project:projectId})

        service.getIssue = (projectId, issueId) ->
            finalUrl = interpolate(itemUrlTemplate, {"url": url("issues"), "id": issueId}, true)
            return queryOne(finalUrl)

        # Get a users with role developer for
        # one concret project.
        service.getUsers = (projectId) ->
            return queryMany(url("users"), {project: projectId})

        service.createTask = (projectId, form) ->
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post(url("tasks"), obj, {headers:headers()})

            promise.success (data, status) ->
                modelurl = interpolate(itemUrlTemplate, {"url": url("tasks"), "id": data.id}, true)
                defered.resolve(new Model(data, modelurl))

            promise.error (data, status) ->
                defered.reject([data, status])

            return defered.promise

        service.createIssue = (projectId, form) ->
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post(url("issues"), obj, {headers:headers()})

            promise.success (data, status) ->
                modelurl = interpolate(itemUrlTemplate, {"url": url("issues"), "id": data.id}, true)
                defered.resolve(new Model(data, modelurl))

            promise.error (data, status) ->
                defered.reject([data, status])

            return defered.promise

        service.createUserStory = (projectId, form) ->
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post(url("userstories"), obj, {headers:headers()})

            promise.success (data, status) ->
                modelurl = interpolate(itemUrlTemplate, {"url": url("userstories"), "id": data.id}, true)
                defered.resolve(new Model(data, modelurl))

            promise.error (data, status) ->
                defered.reject([data, status])

            return defered.promise

        service.createMilestone = (projectId, form) ->
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post(url("milestones"), obj, {headers:headers()})

            promise.success (data, status) ->
                modelurl = interpolate(itemUrlTemplate, {"url": url("milestones"), "id": data.id}, true)
                defered.resolve(new Model(data, modelurl))

            promise.error (data, status) ->
                defered.reject(data, status)

            return defered.promise

        service.getWikiPage = (projectId, slug) ->
            urlTemplate = "%(url)s%(id)s-%(slug)s/"
            finalUrl = interpolate(urlTemplate,
                {"url": url("wikipages"), "id": projectId, "slug": slug}, true)

            return queryOne(finalUrl)

        service.createWikiPage = (projectId, slug, content) ->
            obj =
                "content": content
                "slug": slug
                "project": projectId

            defered = $q.defer()

            promise = $http.post(url("wikipages"), obj, {headers:headers()})

            promise.success (data, status) ->
                modelurl = interpolate(itemUrlTemplate, {"url": url("wikipages"), "id": data.slug}, true)
                defered.resolve(new Model(data, modelurl))

            promise.error (data, status) ->
                defered.reject([data, status])

            return defered.promise

        service.getIssueAttachments = (projectId, issueId) ->
            return queryMany(url("issues/attachments"), {project:projectId, object_id: issueId})

        service.uploadIssueAttachment = (projectId, issueId, file, progress) ->
            defered = $q.defer()

            #uploadProgress = (evt) ->
            #    if (evt.lengthComputable) {
            #        progress = Math.round(evt.loaded * 100 / evt.total)
            #    } else {
            #        progress = 'unable to compute'
            #    }
            #}

            uploadComplete = (evt) ->
                data = JSON.parse(evt.target.responseText)
                defered.resolve(data)

            uploadFailed = (evt) ->
                defered.reject("fail")

            formData = new FormData()
            formData.append("project", projectId)
            formData.append("object_id", issueId)
            formData.append("attached_file", file)

            xhr = new XMLHttpRequest()

            if progress != undefined
                xhr.upload.addEventListener("progress", uploadProgress, false)

            xhr.addEventListener("load", uploadComplete, false)
            xhr.addEventListener("error", uploadFailed, false)
            xhr.open("POST", url("issues/attachments"))
            xhr.setRequestHeader("X-SESSION-TOKEN", storage.get('token'))
            xhr.send(formData)
            return defered.promise

        return service

    $provide.factory("url", ['greenmine.config', urlProvider])
    $provide.factory('resource', ['$http', '$q', 'storage', 'url', 'greenmine.config', resourceProvider])
)
