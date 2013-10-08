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

angular.module('greenmine.services.resource', ['greenmine.config'], ($provide) ->
    resourceProvider = ($http, $q, $gmStorage, $gmUrls, $model, config) ->
        service = {}
        headers = ->
            return {"X-SESSION-TOKEN": $gmStorage.get('token')}

        queryMany = (name, params, options) ->
            defauts = {method: "GET", headers:  headers()}
            current = {url: $gmUrls.api(name), params: params or {}}

            httpParams = _.extend({}, defauts, options, current)
            defered = $q.defer()

            promise = $http(httpParams)
            promise.success (data, status) ->
                models = _.map data, (attrs) -> $model.make_model(name, attrs)
                defered.resolve(models)

            promise.error (data, status) ->
                defered.reject(data, status)

            return defered.promise

        queryOne = (name, id, params, options, cls) ->
            defauts = {method: "GET", headers:  headers()}
            current = {url: "#{$gmUrls.api(name)}/#{id}", params: params or {}}

            httpParams =  _.extend({}, defauts, options, current)

            defered = $q.defer()

            promise = $http(httpParams)
            promise.success (data, status) ->
                defered.resolve($model.make_model(name, data, cls))

            promise.error (data, status) ->
                defered.reject()

            return defered.promise


        # Resource Methods

        # Login request
        service.login = (username, password) ->
            defered = $q.defer()

            onSuccess = (data, status) ->
                $gmStorage.set("token", data["token"])
                defered.resolve(data)

            onError = (data, status) ->
                defered.reject(data)

            postData =
                "username": username
                "password":password

            $http({method:'POST', url: $gmUrls.api('auth'), data: JSON.stringify(postData)})
                .success(onSuccess).error(onError)

            return defered.promise

        # Get a project list
        service.getProjects = -> queryMany('projects')

        service.getProject = (projectId) ->
            return queryOne("projects", projectId)

        # Get roles
        service.getRoles = -> queryMany('roles')

        # Get available task statuses for a project.
        service.getTaskStatuses = (projectId) ->
            return queryMany('choices/task-status', {project: projectId})

        service.getUsPoints = (projectId) ->
            return queryMany('choices/points', {project: projectId})

        service.getPriorities = (projectId) ->
            return queryMany("choices/priorities", {project: projectId})

        service.getSeverities = (projectId) ->
            return queryMany("choices/severities", {project: projectId})

        service.getIssueStatuses = (projectId) ->
            return queryMany("choices/issue-status", {project: projectId})

        service.getIssueTypes = (projectId) ->
            return queryMany("choices/issue-types", {project: projectId})

        service.getUsStatuses = (projectId) ->
            return queryMany("choices/us-status", {project: projectId})

        # Get a milestone lines for a project.
        service.getMilestones = (projectId) ->
            # First step: obtain data
            _getMilestones = ->
                defered = $q.defer()

                params =
                    "method":"GET"
                    "headers": headers()
                    "url": $gmUrls.api("milestones")
                    "params": {"project": projectId}

                $http(params).success((data, status) ->
                    defered.resolve(data)
                ).error((data, status) ->
                    defered.reject(data, status)
                )

                return defered.promise

            # Second step: make user story models
            _makeUserStoryModels = (objects) ->
                for milestone in objects
                    milestone.user_stories = _.map milestone.user_stories, (obj) -> $model.make_model("userstories", obj)

                return objects

            # Third step: make milestone models
            _makeModels = (objects) ->
                return _.map objects, (obj) -> $model.make_model("milestones", obj)

            return _getMilestones().then(_makeUserStoryModels).then(_makeModels)

        service.getMilestone = (projectId, sprintId) ->
            _getMilestone = ->
                defered = $q.defer()

                params =
                    "method": "GET"
                    "headers": headers()
                    "url": "#{$gmUrls.api("milestones")}/#{sprintId}"
                    "params": {"project": projectId}

                $http(params).success((data, status) ->
                    defered.resolve(data)
                ).error((data, status) ->
                    defered.reject(data, status)
                )

                return defered.promise

            # Second step: make user story models
            _makeUserStoryModels = (milestone) ->
                milestone.user_stories = _.map milestone.user_stories, (obj) -> $model.make_model("userstories", obj)

                return milestone

            # Third step: make milestone models
            _makeModel = (milestone) ->
                return $model.make_model("milestone", milestone)

            return _getMilestone().then(_makeUserStoryModels).then(_makeModel)

        # Get unassigned user stories list for a project.
        service.getUnassignedUserStories = (projectId) ->
            return queryMany("userstories", {"project":projectId, "milestone": "null"})

        # Get a user stories list by projectId and sprintId.
        service.getMilestoneUserStories = (projectId, sprintId) ->
            return queryMany("userstories", {"project":projectId, "milestone": sprintId})

        # Get a user stories by projectId and userstory id
        service.getUserStory = (projectId, userStoryId) ->
            return queryOne("userstories", userStoryId, {project:projectId})

        service.getTasks = (projectId, sprintId) ->
            params = {project:projectId}
            if sprintId != undefined
                params.milestone = sprintId

            return queryMany("tasks", params)

        service.getIssues = (projectId) ->
            return queryMany("issues", {project:projectId})

        service.getIssue = (projectId, issueId) ->
            return queryOne("issues", issueId, {project:projectId})

        service.getTask = (projectId, taskId) ->
            return queryOne("tasks", taskId, {project:projectId})

        service.search = (projectId, term) ->
            return queryMany("search", {"project": projectId, "text": term})

        # Get a users with role developer for
        # one concret project.
        service.getUsers = (projectId) ->
            return queryMany("users", {project: projectId})

        service.createTask = (form) ->
            return $model.create("tasks", form)

        service.createIssue = (projectId, form) ->
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post($gmUrls.api("issues"), obj, {headers:headers()})
            promise.success (data, status) ->
                defered.resolve($model.make_model("issues", data))

            promise.error (data, status) ->
                defered.reject()

            return defered.promise

        service.createUserStory = (data) ->
            return $model.create('userstories', data)

        service.createMilestone = (projectId, form) ->
            #return $model.create('milestones', data)
            obj = _.extend({}, form, {project: projectId})
            defered = $q.defer()

            promise = $http.post($gmUrls.api("milestones"), obj, {headers:headers()})

            promise.success (data, status) ->
                defered.resolve($model.make_model("milestones", data))

            promise.error (data, status) ->
                defered.reject()

            return defered.promise

        service.getWikiPage = (projectId, slug) ->
            defered = $q.defer()

            httpParams = {
                method: "GET"
                headers: headers()
                url: $gmUrls.api("wiki")
                params: {project: projectId, slug: slug }
            }

            promise = $http(httpParams)
            promise.success (data) ->
                if data.length == 0
                    defered.reject()
                else
                    defered.resolve($model.make_model("wiki", data[0]))

            promise.error ->
                defered.reject()

            return defered.promise

        service.createWikiPage = (projectId, slug, content) ->
            obj = {
                "content": content
                "slug": slug
                "project": projectId
            }

            defered = $q.defer()

            promise = $http.post($gmUrls.api("wiki"), obj, {headers:headers()})
            promise.success (data, status) ->
                defered.resolve($model.make_model("wiki", slug))

            promise.error (data, status) ->
                defered.reject()

            return defered.promise

        service.getIssueAttachments = (projectId, issueId) ->
            return queryMany("issues/attachments", {project:projectId, object_id: issueId})

        service.getTaskAttachments = (projectId, issueId) ->
            return queryMany("tasks/attachments", {project:projectId, object_id: issueId})


        service.uploadTaskAttachment = (projectId, issueId, file, progress) ->
            defered = Q.defer()

            if file is undefined
                defered.resolve(null)
                return defered.promise

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
            xhr.open("POST", $gmUrls.api("tasks/attachments"))
            xhr.setRequestHeader("X-SESSION-TOKEN", $gmStorage.get('token'))
            xhr.send(formData)
            return defered.promise

        service.uploadIssueAttachment = (projectId, issueId, file, progress) ->
            defered = Q.defer()

            if file is undefined
                defered.resolve(null)
                return defered.promise

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
            xhr.open("POST", $gmUrls.api("issues/attachments"))
            xhr.setRequestHeader("X-SESSION-TOKEN", $gmStorage.get('token'))
            xhr.send(formData)
            return defered.promise

        return service

    $provide.factory('resource', ['$http', '$q', '$gmStorage', '$gmUrls', '$model', 'config', resourceProvider])
)
