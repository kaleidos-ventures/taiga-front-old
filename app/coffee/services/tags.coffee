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

class Persist
    constructor: (@storage, @projectId) -> @items = @read()
    getStorageKey: -> "#{@constructor.storageKey}-project-#{@projectId}"
    read: -> @storage.get(@getStorageKey()) or {}
    save: -> @storage.set(@getStorageKey(), @items)

class Tags extends Persist
    constructor: (storage, projectId) ->
        super storage, projectId
        @tags = @items
    key: (tag) -> tag.name
    setProject: (@projectId) ->
    fetch: (tag) -> @tags[@key(tag)]
    isEmpty: -> _.isEmpty(@tags)
    names: -> _(@tags).map("name").value()
    values: -> _.values(@tags)
    join: (sep=",") -> @names().join(sep)

    store: (tag) ->
        @tags[@key(tag)] = tag
        @save()

    update: (tag, newValues) ->
        @tags[@key(tag)] = _.defaults(newValues, @tags[@key(tag)])
        @save()

    remove: (tag) ->
        delete @tags[@key(tag)]
        @save()

class BacklogTags extends Tags
    @storageKey: "backlog-selected-tags"

class IssuesTags extends Tags
    @storageKey: "issues-selected-tags"
    @scopeVar: "tags"

class NumericIssuesTags extends IssuesTags
    join: (sep=",") -> _(@tags).values().map("id").join(sep)

class IssuesStatusTags extends NumericIssuesTags
    @storageKey: "issues-status-selected-tags"
    @scopeVar: "statusTags"

class IssuesTypeTags extends NumericIssuesTags
    @storageKey: "issues-type-selected-tags"
    @scopeVar: "typeTags"

class IssuesSeverityTags extends NumericIssuesTags
    @storageKey: "issues-severity-selected-tags"
    @scopeVar: "severityTags"

class IssuesPriorityTags extends NumericIssuesTags
    @storageKey: "issues-priority-selected-tags"
    @scopeVar: "priorityTags"

class IssuesOwnerTags extends NumericIssuesTags
    @storageKey: "issues-added-by-selected-tags"
    @scopeVar: "addedByTags"

class IssuesAssigedToTags extends NumericIssuesTags
    @storageKey: "issues-assigned-to-selected-tags"
    @scopeVar: "assignedToTags"

class IssuesOrderBy extends Persist
    @storageKey: "issues-order-by"
    set: (@items) -> @save()
    setDefault: (items) ->
        unless @items.field?
            @items = items
            @save()

    getField: -> @items.field
    isReverse: -> @items.reverse

SelectedTagsProvider = ($gmStorage) ->
    tags = {}
    return (projectId) ->
        unless tags[projectId]?
            tags[projectId] = {
                backlog: new BacklogTags($gmStorage, projectId),
                issues: {
                    tags: new IssuesTags($gmStorage, projectId),
                    type: new IssuesTypeTags($gmStorage, projectId),
                    status: new IssuesStatusTags($gmStorage, projectId),
                    severity: new IssuesSeverityTags($gmStorage, projectId),
                    priority: new IssuesPriorityTags($gmStorage, projectId),
                    owner: new IssuesOwnerTags($gmStorage, projectId),
                    assigned_to: new IssuesAssigedToTags($gmStorage, projectId)
                },
                issues_order: new IssuesOrderBy($gmStorage, projectId)
            }
        return tags[projectId]

module = angular.module('taiga.services.tags', [])
module.factory('SelectedTags', ["$gmStorage", SelectedTagsProvider])
