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


class FiltersService extends TaigaBaseService
    @.$inject = ["$rootScope", "$gmStorage", "$i18next"]

    constructor: (@rootScope, @gmStorage, @i18next) ->
        super()

    # Given a raw filters data of one unique type (like tags, owners,
    # statuses, etc...) return a preprocessed list of filter objects.
    generateFiltersFromGenericList: (data, constants, type) ->
        filters = _.map data, (item) ->
            filterId = item[0]
            filterCounter = item[1]
            resolvedFilter = constants[filterId]

            return {
                "id": filterId,
                "name": resolvedFilter.name,
                "count": filterCounter,
                "type": type,
                "color": resolvedFilter.color
            }

        return filters

    # This function defines a specific behavior for generate the filters
    # data for tags. Works like `generateFiltersFromGenericList`.
    generateFiltersFromTagsList: (data) ->
        filters = _.map data, (item) =>
            filterId = item[0]
            filterCounter = item[1]

            return {
                "id": filterId,
                "name": filterId,
                "count": filterCounter,
                "type": "tags",
                "color": @.getColorForText(filterId)
            }

        return filters

    # This function defines a specific behavior for generate the filters
    # data for users. Works like `generateFiltersFromGenericList`.
    generateFiltersFromUsersList: (data, constants, type) ->
        filters = _.map data, (item) =>
            filterId = item[0]
            filterCounter = item[1]

            tag = {count: filterCounter, type: type}
            if filterId is null
                tag.id = "null"
                tag.name = @i18next.t("common.unassigned")
            else
                user = constants[filterId]
                tag.id = filterId
                tag.name = gm.utils.truncate(user.full_name, 17)

            return tag

        return _.sortBy filters, (item) ->
            if item.id is null
                return "000000000000000"
            return item.name

    # Given a text, convert it to rgb color using a first 6 hex chars
    # from sha1 hash of that text.
    getColorForText: (text) ->
        hash = hex_sha1(text.toLowerCase())
        color = (hash.substring(0,6)
                    .replace("8","0")
                    .replace("9","1")
                    .replace("a","2")
                    .replace("b","3")
                    .replace("c","4")
                    .replace("d","5")
                    .replace("e","6")
                    .replace("f","7"))
        return "##{color}"

    # Some filter constants does not include colors because it are generated
    # from user input. This function attach a rgb color attribute to each
    # filter object using its name attribute as color source.
    # TODO: seems not used, remove (?)
    colorizeTags: (tags) ->
        tags = _.map tags, (item) =>
            item = _.clone(item)
            item.color = @.getColorForText(item.name)
            return item

        return tags

    # Specific logic for issues page that generates a complete filters
    # map from raw filters data obtained from backend.
    generateFiltersForIssues: (data, constants) ->
        filters = {
            statuses: @.generateFiltersFromGenericList(data.statuses, constants.issueStatuses, "status"),
            types: @.generateFiltersFromGenericList(data.types, constants.types, "type"),
            tags: @.generateFiltersFromTagsList(data.tags),
            severities: @.generateFiltersFromGenericList(data.severities, constants.severities, "severity"),
            priorities: @.generateFiltersFromGenericList(data.priorities, constants.priorities, "priority"),
            owners: @.generateFiltersFromUsersList(data.owners, constants.users, "owner"),
            assignedTo: @.generateFiltersFromUsersList(data.assigned_to, constants.users, "assigned")
        }

        return filters

    # Generic method for generate hash from a arbitrary length
    # collection of parameters.
    generateHash: (components=[]) ->
        components = _.map(components, (x) -> JSON.stringify(x))
        return hex_sha1(components.join(":"))

    # Given a preprocessed map of all filters data, returns
    # a plain list/array of selected list that matches the
    # criteria predicate.
    getSelectedFiltersList: (projectId, namespace, filtersData) ->
        allFilterTags = _.flatten(_.values(filtersData))
        return _.filter allFilterTags, (filterItem) =>
            return @.isFilterSelected(projectId, namespace, filterItem)

    filterToText: (filter) ->
        return "#{filter.id}:#{filter.name}:#{filter.type}"

    # Given a namespace and filter, check if specified filter
    # is selected or not.
    isFilterSelected: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}"
        filters = @gmStorage.get(key, [])
        return (filters.indexOf(@.filterToText(filterTag)) != -1)

    selectFilter: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}"

        filters = @gmStorage.get(key, [])
        filterKey = @.filterToText(filterTag)

        pos = filters.indexOf(filterKey)
        if pos == -1
            filters.push(filterKey)
            @gmStorage.set(key, filters)

    unselectFilter: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}"

        filters = @gmStorage.get(key, [])
        filterKey = @.filterToText(filterTag)

        pos = filters.indexOf(filterKey)
        if pos != -1
            filters.splice(pos, 1)
            @gmStorage.set(key, filters)

    # Namespaced method for store ordering. Serves as lightweight
    # abstraction over gmStorage service for simplify access and avoid
    # reuse ordering from one page in an other.
    setOrdering: (projectId, namespace, ordering) ->
        hash = @.generateHash([projectId, namespace])
        @gmStorage.set(hash, ordering)

    # Namespaced method fro obtain stored ordering. This is a reverse
    # method of `setOrdering`.
    getOrdering: (projectId, namespace) ->
        hash = @.generateHash([projectId, namespace])
        return @gmStorage.get(hash)

module = angular.module("taiga.services.tags", ["gmStorage", "i18next"])
module.factory("SelectedTags", ["$gmStorage", SelectedTagsProvider])
module.service("$gmFilters", FiltersService)
