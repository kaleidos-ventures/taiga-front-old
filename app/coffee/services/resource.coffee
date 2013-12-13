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

ResourceProvider = ($http, $q, $gmStorage, $gmUrls, $model, config) ->
    service = {}
    headers = (diablePagination=true) ->
        data = {}
        token = $gmStorage.get('token')

        data["Authorization"] = "Bearer #{token}" if token
        data["X-Disable-Pagination"] = "true" if diablePagination

        return data

    queryMany = (name, params, options, urlParams) ->
        defaultHttpParams = {
            method: "GET",
            headers:  headers(),
            url: $gmUrls.api(name, urlParams)
        }
        if not _.isEmpty(params)
            defaultHttpParams.params = params

        httpParams = _.extend({}, defaultHttpParams, options)
        defered = $q.defer()

        promise = $http(httpParams)
        promise.success (data, status) ->
            models = _.map data, (attrs) -> $model.make_model(name, attrs)
            defered.resolve(models)

        promise.error (data, status) ->
            defered.reject(data, status)

        return defered.promise

    queryRaw = (name, id, params, options, cls) ->
        defaultHttpParams = {method: "GET", headers:  headers()}

        if id
            defaultHttpParams.url = "#{$gmUrls.api(name)}/#{id}"
        else
            defaultHttpParams.url = "#{$gmUrls.api(name)}"

        if not _.isEmpty(params)
            defaultHttpParams.params = params

        httpParams =  _.extend({}, defaultHttpParams, options)

        defered = $q.defer()

        promise = $http(httpParams)
        promise.success (data, status) ->
            defered.resolve(data, cls)

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    queryOne = (name, id, params, options, cls) ->
        defaultHttpParams = {method: "GET", headers:  headers()}

        if id
            defaultHttpParams.url = "#{$gmUrls.api(name)}/#{id}"
        else
            defaultHttpParams.url = "#{$gmUrls.api(name)}"

        if not _.isEmpty(params)
            defaultHttpParams.params = params

        httpParams =  _.extend({}, defaultHttpParams, options)

        defered = $q.defer()

        promise = $http(httpParams)
        promise.success (data, status) ->
            defered.resolve($model.make_model(name, data, cls))

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    queryManyPaginated = (name, params, options, cls, urlParams) ->
        defaultHttpParams = {
            method: "GET",
            headers: headers(false),
            url: $gmUrls.api(name, urlParams)
        }
        if not _.isEmpty(params)
            defaultHttpParams.params = params

        httpParams =  _.extend({}, defaultHttpParams, options)
        defered = $q.defer()

        promise = $http(httpParams)
        promise.success (data, status, headersFn) ->
            currentHeaders = headersFn()

            result = {}
            result.models = _.map(data, (attrs) -> $model.make_model(name, attrs, cls))
            result.count = parseInt(currentHeaders["x-pagination-count"], 10)
            result.current = parseInt(currentHeaders["x-pagination-current"] or 1, 10)
            result.paginatedBy = parseInt(currentHeaders["x-paginated-by"], 10)

            defered.resolve(result)

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    # Resource Methods
    service.register = (formdata) ->
        defered = $q.defer()

        onSuccess = (data, status) ->
            $gmStorage.set("token", data["auth_token"])
            user = $model.make_model("users", data)
            defered.resolve(user)

        onError = (data, status) ->
            defered.reject(data)

        promise = $http({method:'POST', url: $gmUrls.api('auth-register'), data: JSON.stringify(formdata)})
        promise.success(onSuccess)
        promise.error(onError)

        return defered.promise

    # Login request
    service.login = (username, password) ->
        defered = $q.defer()

        onSuccess = (data, status) ->
            $gmStorage.set("token", data["auth_token"])
            user = $model.make_model("users", data)
            defered.resolve(user)

        onError = (data, status) ->
            defered.reject(data)

        postData =
            "username": username
            "password":password

        $http({method:'POST', url: $gmUrls.api('auth'), data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    service.recovery = (email) ->
        defered = $q.defer()
        postData = {username: email}
        url = $gmUrls.api("users-password-recovery")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        $http({method: "POST", url: url, data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    service.changePasswordFromRecovery = (token, password) ->
        defered = $q.defer()
        postData = {password: password, token: token}
        url = $gmUrls.api("users-change-password-from-recovery")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        $http({method: "POST", url: url, data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    service.changePasswordForCurrentUser = (password) ->
        defered = $q.defer()
        postData = {password: password}
        url = $gmUrls.api("users-change-password")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        $http({method: "POST", url: url, data: JSON.stringify(postData), headers: headers()})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    # Get a site
    service.getSite = -> queryOne('sites')

    # Get a members list
    service.getSiteMembers = -> queryMany('site-members')

    # Create a project
    service.createProject = (data) ->
        return $model.create("site-projects", data)

    # Get a project list
    service.getProjects = -> queryMany('projects')

    # Get a project
    service.getProject = (projectId) ->
        return queryOne("projects", projectId)

    # Get a project stats
    service.getProjectStats = (projectId) ->
        return queryOne("projects", "#{projectId}/stats")

    # Get a issues stats
    service.getIssuesStats = (projectId) ->
        return queryOne("projects", "#{projectId}/issues_stats")

    # Get a project tags
    service.getProjectTags = (projectId) ->
        return queryRaw("projects", "#{projectId}/tags")

    # Get a issues filters
    service.getIssuesFiltersData = (projectId) ->
        return queryOne("projects", "#{projectId}/issue_filters_data")

    # Create a memberships
    service.createMembership = (form) ->
        return $model.create("memberships", form)

    # Get roles
    service.getRoles = -> queryMany('roles')

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

    service.getMilestoneStats = (sprintId) ->
        return queryOne("milestones", "#{sprintId}/stats")

    # Get unassigned user stories list for a project.
    service.getUnassignedUserStories = (projectId) ->
        return queryMany("userstories", {"project":projectId, "milestone": "null"})

    # Get a user stories list by projectId and sprintId.
    service.getMilestoneUserStories = (projectId, sprintId) ->
        return queryMany("userstories", {"project":projectId, "milestone": sprintId})

    # Get a user stories by projectId and userstory id
    service.getUserStory = (projectId, userStoryId) ->
        return queryOne("userstories", userStoryId, {project:projectId})

    service.getUserStoryHistorical = (userStoryId, filters={}) ->
        urlParams = [userStoryId]
        parameters = _.extend({}, filters)
        return queryManyPaginated("userstories-historical", parameters, null , null,
                                  urlParams)

    service.getTasks = (projectId, sprintId) ->
        params = {project:projectId}
        if sprintId != undefined
            params.milestone = sprintId

        return queryMany("tasks", params)

    service.getIssues = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryManyPaginated("issues", parameters)

    service.getIssue = (projectId, issueId) ->
        return queryOne("issues", issueId, {project:projectId})

    service.getIssueHistorical = (issueId, filters={}) ->
        urlParams = [issueId]
        parameters = _.extend({}, filters)
        return queryManyPaginated("issues-historical", parameters, null , null, urlParams)

    service.getIssuesFiltersData = (projectId) ->
        return queryOne("projects", "#{projectId}/issue_filters_data")

    service.getTask = (projectId, taskId) ->
        return queryOne("tasks", taskId, {project:projectId})

    service.getTaskHistorical = (taskId, filters={}) ->
        urlParams = [taskId]
        parameters = _.extend({}, filters)
        return queryManyPaginated("tasks-historical", parameters, null , null, urlParams)

    service.search = (projectId, term) ->
        defered = $q.defer()

        params =
            "method": "GET"
            "headers": headers()
            "url": $gmUrls.api("search")
            "params": {"project": projectId, "text": term}

        promise = $http(params)
        promise.success (data, status) ->
            defered.resolve(data)

        promise.error (data, status) ->
            defered.reject(data, status)

        return defered.promise

    # Get a users with role developer for
    # one concret project.
    service.getUsers = (projectId) ->
        if projectId
            params = {project: projectId}
        else
            params = {}
        return queryMany("users", params)

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

    service.createBulkUserStories = (projectId, form) ->
        obj = _.extend({}, form, {projectId: projectId})
        return $http.post($gmUrls.api(""), obj, {headers:headers()})

    service.updateBulkUserStoriesOrder = (projectId, data) ->
        obj = {
            projectId: projectId
            bulkStories: data
        }
        return $http.post($gmUrls.api("bulk-update-us-order"), obj, {headers:headers()})

    service.createMilestone = (projectId, form) ->
        #return $model.create('milestones', data)
        obj = _.extend({}, form, {project: projectId})
        defered = $q.defer()

        promise = $http.post($gmUrls.api("milestones"), obj, {headers:headers()})

        promise.success (data, status) ->
            defered.resolve($model.make_model("milestones", data))

        promise.error (data, status) ->
            defered.reject(data)

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

    service.getWikiPageHistorical = (wikiId, filters={}) ->
        urlParams = [wikiId]
        parameters = _.extend({}, filters)
        return queryManyPaginated("wiki-historical", parameters, null , null, urlParams)

    service.createTask = (form) ->
        return $model.create("tasks", form)

    service.restoreWikiPage = (wikiPageId, versionId) ->
        url = "#{$gmUrls.api("wiki-restore", [wikiPageId])}/#{versionId}"

        defered = $q.defer()

        promise = $http.post(url, {}, {headers:headers()})
        promise.success (data, status) ->
            defered.resolve($model.make_model("wiki", data))

        promise.error (data, status) ->
            defered.reject(data, status)

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
            defered.resolve($model.make_model("wiki", data))

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    service.getIssueAttachments = (projectId, issueId) ->
        return queryMany("issues/attachments", {project: projectId, object_id: issueId})

    service.getTaskAttachments = (projectId, taskId) ->
        return queryMany("tasks/attachments", {project: projectId, object_id: taskId})

    service.getUserStoryAttachments = (projectId, userStoryId) ->
        return queryMany("userstories/attachments", {project: projectId, object_id: userStoryId})

    service.getWikiPageAttachments = (projectId, wikiPageId) ->
        return queryMany("wiki/attachments", {project: projectId, object_id: wikiPageId})

    service.uploadIssueAttachment = (projectId, issueId, file, progress) ->
        defered = $q.defer()

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
        xhr.setRequestHeader("Authorization", "Bearer #{$gmStorage.get('token')}")
        xhr.send(formData)
        return defered.promise

    service.uploadTaskAttachment = (projectId, taskId, file, progress) ->
        defered = $q.defer()

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
        formData.append("object_id", taskId)
        formData.append("attached_file", file)

        xhr = new XMLHttpRequest()

        if progress != undefined
            xhr.upload.addEventListener("progress", uploadProgress, false)

        xhr.addEventListener("load", uploadComplete, false)
        xhr.addEventListener("error", uploadFailed, false)
        xhr.open("POST", $gmUrls.api("tasks/attachments"))
        xhr.setRequestHeader("Authorization", "Bearer #{$gmStorage.get('token')}")
        xhr.send(formData)
        return defered.promise

    service.uploadUserStoryAttachment = (projectId, userStoryId, file, progress) ->
        defered = $q.defer()

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
        formData.append("object_id", userStoryId)
        formData.append("attached_file", file)

        xhr = new XMLHttpRequest()

        if progress != undefined
            xhr.upload.addEventListener("progress", uploadProgress, false)

        xhr.addEventListener("load", uploadComplete, false)
        xhr.addEventListener("error", uploadFailed, false)
        xhr.open("POST", $gmUrls.api("userstories/attachments"))
        xhr.setRequestHeader("Authorization", "Bearer #{$gmStorage.get('token')}")
        xhr.send(formData)
        return defered.promise

    service.uploadWikiPageAttachment = (projectId, wikiPageId, file, progress) ->
        defered = $q.defer()

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
        formData.append("object_id", wikiPageId)
        formData.append("attached_file", file)

        xhr = new XMLHttpRequest()

        if progress != undefined
            xhr.upload.addEventListener("progress", uploadProgress, false)

        xhr.addEventListener("load", uploadComplete, false)
        xhr.addEventListener("error", uploadFailed, false)
        xhr.open("POST", $gmUrls.api("wiki/attachments"))
        xhr.setRequestHeader("Authorization", "Bearer #{$gmStorage.get('token')}")
        xhr.send(formData)
        return defered.promise

    service.getSiteInfo = () ->
        httpParams = {
            method: "GET"
            headers: headers()
            url: $gmUrls.api("sites")
        }
        defered = $q.defer()

        promise = $http(httpParams)
        promise.success (data, status, headersFn) ->
            defered.resolve({"headers": headersFn(), "data": data})

        promise.error ->
            defered.reject()

        return defered.promise

    service.getUserStoryStatuses = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/userstory-statuses", parameters)

    service.createUserStoryStatus = (form) ->
        return $model.create("choices/userstory-statuses", form)

    service.getPoints = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/points", parameters)

    service.createPoints = (form) ->
        return $model.create("choices/points", form)

    service.getTaskStatuses = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/task-statuses", parameters)

    service.createTaskStatus = (form) ->
        return $model.create("choices/task-statuses", form)

    service.getIssueStatuses = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/issue-statuses", parameters)

    service.createIssueStatus = (form) ->
        return $model.create("choices/issue-statuses", form)

    service.getIssueTypes = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/issue-types", parameters)

    service.createIssueType = (form) ->
        return $model.create("choices/issue-types", form)

    service.getPriorities = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/priorities", parameters)

    service.createPriority = (form) ->
        return $model.create("choices/priorities", form)

    service.getSeverities = (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return queryMany("choices/severities", parameters)

    service.createSeverity = (form) ->
        return $model.create("choices/severities", form)

    return service

module = angular.module('greenmine.services.resource', ['greenmine.config'])
module.factory('resource', ['$http', '$q', '$gmStorage', '$gmUrls', '$model', 'config', ResourceProvider])
