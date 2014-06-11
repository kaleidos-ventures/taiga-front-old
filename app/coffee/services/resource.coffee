# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class ResourceService extends TaigaBaseService
    @.$inject = ["$http", "$q", "$gmAuth", "$gmUrls", "$model",
                 "$rootScope", "$i18next", "$filter", "$log", "$cacheFactory"]

    constructor: (@http, @q, @gmAuth, @gmUrls, @model, @rootScope,
                  @i18next, @filter, @log, @cacheFactory) ->
        _cache = @cacheFactory("httpCache", 512)
        super()

    _headers: (disablePagination=true) ->
        data = {}
        token = @gmAuth.getToken()

        data["Authorization"] = "Bearer #{token}" if token
        data["X-Disable-Pagination"] = "true" if disablePagination

        return data

    _queryMany: (name, params, options, urlparams) ->
        defaultHttpParams = {
            method: "GET",
            headers:  @_headers(),
            url: @gmUrls.api(name, urlparams)
        }

        httpParams = _.extend({}, defaultHttpParams, options)
        if not _.isEmpty(params)
            httpParams.params = params

        defered = @q.defer()
        promise = @http(httpParams)

        promise.success (data, status) =>
            models = _.map data, (attrs) => @model.make_model(name, attrs)
            defered.resolve(models)

        promise.error (data, status) ->
            defered.reject(data)

        return defered.promise

    _queryRaw: (name, id, params, options, urlparams) ->
        defaultHttpParams = {method: "GET", headers:  @_headers()}
        httpParams =  _.extend({}, defaultHttpParams, options)

        if id
            httpParams.url = "#{@gmUrls.api(name, urlparams)}/#{id}"
        else
            httpParams.url = "#{@gmUrls.api(name, urlparams)}"

        if not _.isEmpty(params)
            httpParams.params = params

        defered = @q.defer()
        promise = @http(httpParams)

        promise.success (data, status) ->
            defered.resolve(data)

        promise.error (data, status) ->
            defered.reject(data)

        return defered.promise

    _queryOne: (name, id, params, options, urlparams, cls) ->
        defaultHttpParams = {method: "GET", headers:  @_headers()}
        httpParams =  _.extend({}, defaultHttpParams, options)

        if not _.isEmpty(params)
            httpParams.params = params

        if id
            httpParams.url = "#{@gmUrls.api(name, urlparams)}/#{id}"
        else
            httpParams.url = "#{@gmUrls.api(name, urlparams)}"

        defered = @q.defer()
        promise = @http(httpParams)

        promise.success (data, status) =>
            defered.resolve(@model.make_model(name, data, cls))

        promise.error (data, status) ->
            defered.reject(data)

        return defered.promise

    _queryManyPaginated: (name, params, options, urlparams, cls) ->
        defaultHttpParams = {
            method: "GET",
            headers: @_headers(false),
            url: @gmUrls.api(name, urlparams)
        }

        httpParams =  _.extend({}, defaultHttpParams, options)
        if not _.isEmpty(params)
            httpParams.params = params

        defered = @q.defer()
        promise = @http(httpParams)

        promise.success (data, status, headersFn) =>
            currentHeaders = headersFn()

            result = {}
            result.models = _.map(data, (attrs) => @model.make_model(name, attrs, cls))
            result.count = parseInt(currentHeaders["x-pagination-count"], 10)
            result.current = parseInt(currentHeaders["x-pagination-current"] or 1, 10)
            result.paginatedBy = parseInt(currentHeaders["x-paginated-by"], 10)

            defered.resolve(result)

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    # Resource Methods
    register: (formdata) ->
        defered = @q.defer()

        onSuccess = (data, status) =>
            user = @model.make_model("users", data)
            @gmAuth.setToken(data["auth_token"])
            @gmAuth.setUser(user)

            defered.resolve(user)

        onError = (data, status) ->
            defered.reject(data)

        promise = @http({method:"POST", url: @gmUrls.api("auth-register"), data: JSON.stringify(formdata)})
        promise.success(onSuccess)
        promise.error(onError)

        return defered.promise

    # Login request
    login: (username, password) ->
        defered = @q.defer()

        onSuccess = (data, status) =>
            user = @model.make_model("users", data)
            @gmAuth.setToken(data["auth_token"])
            @gmAuth.setUser(user)

            defered.resolve(user)

        onError = (data, status) ->
            defered.reject(data)

        postData = {
            username: username
            password: password
            type: "normal"
        }

        @http({method:"POST", url: @gmUrls.api("auth"), data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    gitHubLogin: (code) ->
        defered = @q.defer()

        onSuccess = (data, status) =>
            user = @model.make_model("users", data)
            @gmAuth.setToken(data["auth_token"])
            @gmAuth.setUser(user)

            defered.resolve(user)

        onError = (data, status) ->
            defered.reject(data)

        postData = {
            code: code
            type: "github"
        }

        @http({method:"POST", url: @gmUrls.api("auth"), data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    recovery: (email) ->
        defered = @q.defer()
        postData = {username: email}
        url = @gmUrls.api("users-password-recovery")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        @http({method: "POST", url: url, data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    changePasswordFromRecovery: (token, password) ->
        defered = @q.defer()
        postData = {password: password, token: token}
        url = @gmUrls.api("users-change-password-from-recovery")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        @http({method: "POST", url: url, data: JSON.stringify(postData)})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    changePasswordForCurrentUser: (password) ->
        defered = @q.defer()
        postData = {password: password}
        url = @gmUrls.api("users-change-password")

        onSuccess = (data, status) ->
            defered.resolve(data)

        onError = (data, status) ->
            defered.reject(data)

        @http({method: "POST", url: url, data: JSON.stringify(postData), headers: @_headers()})
            .success(onSuccess)
            .error(onError)

        return defered.promise

    resolve: (options) ->
        params = {}
        params.project = options.pslug if options.pslug?
        params.us = options.usref if options.usref?
        params.task = options.taskref if options.taskref?
        params.issue = options.issueref if options.issueref?
        params.milestone = options.mlref if options.mlref?
        return @_queryRaw("resolver", null, params, {cache:@_cache})

    # Get a site
    getSite: -> @_queryOne("sites")

    # Get project templates
    getProjectTemplates: -> @_queryMany("project-templates")

    # Get project templates
    createProjectTemplateFromProject: (projectId, templateName, templateDescription) ->
        defered = @q.defer()
        obj = {
            project_id: projectId,
            template_name: templateName,
            template_description: templateDescription
        }
        promise = @http.post("#{@gmUrls.api("project-templates")}/create_from_project", obj, {headers:@_headers()})
        promise.success (data, status) =>
            defered.resolve(@model.make_model("project-templates", data))

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    # Get a members list
    getSiteMembers: -> @_queryMany("site-members")

    # Create a project
    createProject: (data, templateName) ->
        return @model.create("site-projects", data, @model.Model, {}, {template: templateName})

    # Get a project list
    getProjects: -> @_queryMany("projects")

    # Get a project list
    getPermissions: -> @_queryMany("permissions")

    # Get a project
    getProject: (projectId) ->
        return @_queryOne("projects", projectId, {cache:@_cache})

    # Get a project stats
    getProjectStats: (projectId) ->
        return @_queryOne("projects", "#{projectId}/stats")

    # Get a issues stats
    getIssuesStats: (projectId) ->
        return @_queryOne("projects", "#{projectId}/issues_stats")

    # Get a project tags
    getProjectTags: (projectId) ->
        return @_queryRaw("projects", "#{projectId}/tags")

    # Get a issues filters
    getIssuesFiltersData: (projectId) ->
        return @_queryOne("projects", "#{projectId}/issue_filters_data")

    # Create a memberships
    createMembership: (form) ->
        return @model.create("memberships", form)

    # Get roles
    getRoles: (projectId) ->
        return @_queryMany("roles", {project: projectId}, {cache:@_cache})

    # Create role
    createRole: (projectId, role) ->
        role.project = projectId
        return @model.create("roles", role)

    # Get a milestone lines for a project.
    getMilestones: (projectId) ->
        # First step: obtain data
        _getMilestones = =>
            defered = @q.defer()

            params =
                "method":"GET"
                "headers": @_headers()
                "url": @gmUrls.api("milestones")
                "params": {"project": projectId}

            @http(params).success((data, status) ->
                defered.resolve(data)
            ).error((data, status) ->
                defered.reject(data, status)
            )

            return defered.promise

        # Second step: make user story models
        _makeUserStoryModels = (objects) =>
            for milestone in objects
                milestone.user_stories = _.map milestone.user_stories, (obj) => @model.make_model("userstories", obj)

            return objects

        # Third step: make milestone models
        _makeModels = (objects) =>
            return _.map objects, (obj) => @model.make_model("milestones", obj)

        return _getMilestones().then(_makeUserStoryModels).then(_makeModels)

    getMilestone: (projectId, sprintId) ->
        _getMilestone = =>
            defered = @q.defer()

            params =
                "method": "GET"
                "headers": @_headers()
                "url": "#{@gmUrls.api("milestones")}/#{sprintId}"
                "params": {"project": projectId}

            @http(params).success((data, status) ->
                defered.resolve(data)
            ).error((data, status) ->
                defered.reject(data, status)
            )

            return defered.promise

        # Second step: make user story models
        _makeUserStoryModels = (milestone) =>
            milestone.user_stories = _.map milestone.user_stories, (obj) => @model.make_model("userstories", obj)

            return milestone

        # Third step: make milestone models
        _makeModel = (milestone) =>
            return @model.make_model("milestone", milestone)

        return _getMilestone().then(_makeUserStoryModels).then(_makeModel)

    getMilestoneStats: (sprintId) ->
        return @_queryOne("milestones", "#{sprintId}/stats")

    # Get unassigned user stories list for a project.
    getUnassignedUserStories: (projectId) ->
        return @_queryMany("userstories", {"project":projectId, "milestone": "null"})

    # Get all user stories list for a project.
    getUserStories: (projectId) ->
        return @_queryMany("userstories", {"project":projectId})

    # Get a user stories list by projectId and sprintId.
    getMilestoneUserStories: (projectId, sprintId) ->
        return @_queryMany("userstories", {"project":projectId, "milestone": sprintId})

    # Get a user stories by projectId and userstory id
    getUserStory: (projectId, userStoryId, params) ->
        params = _.extend({}, params, {project: projectId})
        return @_queryOne("userstories", userStoryId, params)

    getTasks: (projectId, sprintId) ->
        params = {project:projectId}
        if sprintId != undefined
            params.milestone = sprintId

        return @_queryMany("tasks", params)

    getIssues: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryManyPaginated("issues", parameters)

    getIssue: (projectId, issueId, params) ->
        params = _.extend({}, params, {project: projectId})
        return @_queryOne("issues", issueId, params)

    getTask: (projectId, taskId) ->
        return @_queryOne("tasks", taskId, {project:projectId})

    search: (projectId, term, getAll) ->
        defered = @q.defer()

        params = {
            "method": "GET"
            "headers": @_headers()
            "url": @gmUrls.api("search")
            "params": {"project": projectId, "text": term, "get_all": getAll or false}
            "cache": false
        }

        promise = @http(params)
        promise.success (data, status) ->
            defered.resolve(data)

        promise.error (data, status) ->
            defered.reject(data, status)

        return defered.promise

    # Get a users with role developer for
    # one concret project.
    getUsers: (projectId) ->
        if projectId
            params = {project: projectId}
        else
            params = {}
        return @_queryMany("users", params)

    createIssue: (projectId, form) ->
        obj = _.extend({}, form, {project: projectId})
        defered = @q.defer()

        promise = @http.post(@gmUrls.api("issues"), obj, {headers:@_headers()})
        promise.success (data, status) =>
            defered.resolve(@model.make_model("issues", data))

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    createUserStory: (data) ->
        return @model.create("userstories", data)

    createBulkUserStories: (projectId, form) ->
        obj = _.extend({}, form, {projectId: projectId})
        return @http.post(@gmUrls.api("bulk-create-us"), obj, {headers:@_headers()})

    createBulkTasks: (projectId, usId, form) ->
        obj = _.extend({}, form, {projectId: projectId, usId: usId})
        return @http.post(@gmUrls.api("bulk-create-tasks"), obj, {headers:@_headers()})

    updateBulkUserStoriesOrder: (projectId, data) ->
        obj = {
            projectId: projectId
            bulkStories: data
        }
        return @http.post(@gmUrls.api("bulk-update-us-order"), obj, {headers:@_headers()})

    setUsMilestone: (usId, milestoneId) ->
        defered = @q.defer()

        obj = { milestone: milestoneId }

        promise = @http({
            method: "PATCH",
            url: "#{@gmUrls.api("userstories")}/#{usId}",
            data: obj, headers:@_headers()})

        promise.success (data, status) =>
            defered.resolve(@model.make_model("userstories", data))

        promise.error (data, status) ->
            defered.reject(data)

        return defered.promise

    createMilestone: (projectId, form) ->
        obj = _.extend({}, form, {project: projectId})
        defered = @q.defer()

        promise = @http.post(@gmUrls.api("milestones"), obj, {headers:@_headers()})

        promise.success (data, status) =>
            defered.resolve(@model.make_model("milestones", data))

        promise.error (data, status) ->
            defered.reject(data)

        return defered.promise

    getWikiPage: (projectId, slug) ->
        defered = @q.defer()

        httpParams = {
            method: "GET"
            headers: @_headers()
            url: @gmUrls.api("wiki")
            params: {project: projectId, slug: slug }
        }

        promise = @http(httpParams)
        promise.success (data) =>
            if data.length == 0
                defered.reject()
            else
                defered.resolve(@model.make_model("wiki", data[0]))

        promise.error ->
            defered.reject()

        return defered.promise

    renderWiki: (projectId, text) ->
        defered = @q.defer()

        httpParams = {
            method: "POST"
            headers: @_headers()
            url: "#{@gmUrls.api("wiki")}/render"
            data: {project_id: projectId, content: text }
        }

        promise = @http(httpParams)
        promise.success (data) =>
            defered.resolve(data)

        promise.error ->
            defered.reject()

        return defered.promise

    createTask: (form) ->
        return @model.create("tasks", form)

    restoreWikiPage: (wikiPageId, versionId) ->
        url = "#{@gmUrls.api("wiki-restore", [wikiPageId])}"

        defered = @q.defer()

        promise = @http.post(url, {}, {headers:@_headers(), params: {version: versionId}})
        promise.success (data, status) =>
            defered.resolve(@model.make_model("wiki", data))

        promise.error (data, status) ->
            defered.reject(data, status)

        return defered.promise

    createWikiPage: (projectId, slug, content) ->
        obj = {
            "content": content
            "slug": slug
            "project": projectId
        }

        defered = @q.defer()

        promise = @http.post(@gmUrls.api("wiki"), obj, {headers:@_headers()})
        promise.success (data, status) =>
            defered.resolve(@model.make_model("wiki", data))

        promise.error (data, status) ->
            defered.reject()

        return defered.promise

    _uploadAttachment: (projectId, objectId, file, progress, apiUrlKey) ->
        defered = @q.defer()

        if file is undefined
            defered.resolve(null)
            return defered.promise

        uploadProgress = (evt) =>
            @rootScope.$apply =>
                file.status = "in-progress"
                file.totalSize = evt.total
                file.uploadSize = evt.loaded
                file.progressSizeData = @i18next.t("common.file-upload-data", {
                    upload: @filter("sizeFormat")(evt.loaded),
                    total: @filter("sizeFormat")(evt.total)
                })
                file.uploadPercent = Math.round((evt.loaded / evt.total) * 100)

        uploadComplete = (evt) =>
            @rootScope.$apply ->
                file.status = "done"
                try
                    data = JSON.parse(evt.target.responseText)
                catch
                    data = {}
                defered.resolve(data)

        uploadFailed = (evt) =>
            @rootScope.$apply ->
                file.status = "error"
                defered.reject("fail")

        formData = new FormData()
        formData.append("project", projectId)
        formData.append("object_id", objectId)
        formData.append("attached_file", file)

        xhr = new XMLHttpRequest()

        if progress?
            xhr.upload.addEventListener("progress", uploadProgress, false)
        xhr.addEventListener("load", uploadComplete, false)
        xhr.addEventListener("error", uploadFailed, false)
        xhr.open("POST", @gmUrls.api(apiUrlKey))
        xhr.setRequestHeader("Authorization", "Bearer #{@gmAuth.getToken()}")
        xhr.setRequestHeader('Accept', 'application/json')
        xhr.send(formData)
        return defered.promise

    uploadIssueAttachment: (projectId, issueId, file, progress=true) ->
        @_uploadAttachment(projectId, issueId, file, progress, "issues/attachments")

    uploadTaskAttachment: (projectId, taskId, file, progress=true) ->
        @_uploadAttachment(projectId, taskId, file, progress, "tasks/attachments")

    uploadUserStoryAttachment: (projectId, userStoryId, file, progress=true) ->
        @_uploadAttachment(projectId, userStoryId, file, progress, "userstories/attachments")

    uploadWikiPageAttachment: (projectId, wikiPageId, file, progress=true) ->
        @_uploadAttachment(projectId, wikiPageId, file, progress, "wiki/attachments")

    getIssueAttachments: (projectId, issueId) ->
        return @_queryMany("issues/attachments", {project: projectId, object_id: issueId})

    getTaskAttachments: (projectId, taskId) ->
        return @_queryMany("tasks/attachments", {project: projectId, object_id: taskId})

    getUserStoryAttachments: (projectId, userStoryId) ->
        return @_queryMany("userstories/attachments", {project: projectId, object_id: userStoryId})

    getWikiPageAttachments: (projectId, wikiPageId) ->
        return @_queryMany("wiki/attachments", {project: projectId, object_id: wikiPageId})

    getSiteInfo: () ->
        httpParams = {
            method: "GET"
            headers: @_headers()
            url: @gmUrls.api("sites")
        }
        defered = @q.defer()

        promise = @http(httpParams)
        promise.success (data, status, headersFn) ->
            defered.resolve({"headers": headersFn(), "data": data})

        promise.error ->
            defered.reject()

        return defered.promise

    getUserStoryStatuses: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/userstory-statuses", parameters)

    createUserStoryStatus: (form) ->
        return @model.create("choices/userstory-statuses", form)

    updateBulkUserStoryStatusesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_userstory_statuses: data
        }
        return @http.post(@gmUrls.api("choices/userstory-statuses/bulk-update-order"), obj, {headers:@_headers()})

    getPoints: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/points", parameters)

    createPoints: (form) ->
        return @model.create("choices/points", form)

    updateBulkPointsOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_points: data
        }
        return @http.post(@gmUrls.api("choices/points/bulk-update-order"), obj, {headers:@_headers()})

    getTaskStatuses: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/task-statuses", parameters)

    createTaskStatus: (form) ->
        return @model.create("choices/task-statuses", form)

    updateBulkTaskStatusesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_task_statuses: data
        }
        return @http.post(@gmUrls.api("choices/task-statuses/bulk-update-order"), obj, {headers:@_headers()})

    getIssueStatuses: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/issue-statuses", parameters)

    createIssueStatus: (form) ->
        return @model.create("choices/issue-statuses", form)

    updateBulkIssueStatusesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_issue_statuses: data
        }
        return @http.post(@gmUrls.api("choices/issue-statuses/bulk-update-order"), obj, {headers:@_headers()})

    getIssueTypes: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/issue-types", parameters, {cache:false})

    createIssueType: (form) ->
        return @model.create("choices/issue-types", form)

    updateBulkIssueTypesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_issue_types: data
        }
        return @http.post(@gmUrls.api("choices/issue-types/bulk-update-order"), obj, {headers:@_headers()})

    getPriorities: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/priorities", parameters, {cache:false})

    createPriority: (form) ->
        return @model.create("choices/priorities", form)

    updateBulkPrioritiesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_priorities: data
        }
        return @http.post(@gmUrls.api("choices/priorities/bulk-update-order"), obj, {headers:@_headers()})

    getSeverities: (projectId, filters={}) ->
        parameters = _.extend({}, filters, {project:projectId})
        return @_queryMany("choices/severities", parameters)

    createSeverity: (form) ->
        return @model.create("choices/severities", form)

    updateBulkSeveritiesOrder: (projectId, data) ->
        obj = {
            project: projectId
            bulk_severities: data
        }
        return @http.post(@gmUrls.api("choices/severities/bulk-update-order"), obj, {headers:@_headers()})

    getHistory: (type, pk, params) ->
        return @_queryRaw("history/#{type}", pk, params)


module = angular.module("taiga.services.resource", ["taiga.services.auth", "gmUrls",
                                                    "taiga.services.model", "i18next"])
module.service("resource", ResourceService)
