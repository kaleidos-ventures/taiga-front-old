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
    constructor: (@storage) -> @items = @read()
    read: -> @storage.get(@constructor.storageKey) or {}
    save: -> @storage.set(@constructor.storageKey, @items)

class Tags extends Persist
    constructor: (storage) ->
        super storage
        @tags = @items
    key: (tag) -> tag.name
    fetch: (tag) -> @tags[@key(tag)]
    isEmpty: -> _.isEmpty(@tags)
    names: -> _(@tags).map("name").value()
    values: -> _.values(@tags)
    join: (sep=",") -> @names().join(sep)

    store: (tag) ->
         @tags[@key(tag)] = tag
         @save()

    remove: (tag) ->
        delete @tags[@key(tag)]
        @save()

class BacklogTags extends Tags
    @storageKey: "backlog-selected-tags"

class IssuesTags extends Tags
    @storageKey: "issues-selected-tags"

class NumericIssuesTags extends IssuesTags
    join: (sep=",") -> _(@tags).values().map("id").join(sep)

class IssuesStatusTags extends NumericIssuesTags
    @storageKey: "issues-status-selected-tags"

class IssuesTypeTags extends NumericIssuesTags
    @storageKey: "issues-type-selected-tags"

class IssuesSeverityTags extends NumericIssuesTags
    @storageKey: "issues-severity-selected-tags"

class IssuesPriorityTags extends NumericIssuesTags
    @storageKey: "issues-priority-selected-tags"

class IssuesOwnerTags extends NumericIssuesTags
    @storageKey: "issues-added-by-selected-tags"

class IssuesAssigedToTags extends NumericIssuesTags
    @storageKey: "issues-assigned-to-selected-tags"

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
    return {
        backlog: new BacklogTags($gmStorage),
        issues: {
            tags: new IssuesTags($gmStorage),
            type: new IssuesTypeTags($gmStorage),
            status: new IssuesStatusTags($gmStorage),
            severity: new IssuesSeverityTags($gmStorage),
            priority: new IssuesPriorityTags($gmStorage),
            owner: new IssuesOwnerTags($gmStorage),
            assigned_to: new IssuesAssigedToTags($gmStorage)
        },
        issues_order: new IssuesOrderBy($gmStorage)
    }

module = angular.module('taiga.services.tags', [])
module.factory('SelectedTags', ["$gmStorage", SelectedTagsProvider])
