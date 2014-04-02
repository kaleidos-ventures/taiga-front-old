# Copyright 2014 Andrey Antukh <niwi@niwi.be>
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
            if item.id == "null"
                return "000000000000000"
            return item.name

    # User stories have tags attribute with plain
    # text tags, that should be converted on
    generateTagsFromUserStoriesList: (userstories) ->
        plainTags = _.flatten(_.map(userstories, "tags"))
        tags = _.map _.countBy(plainTags), (value, key) ->
            return [key, value]

        return @.generateFiltersFromTagsList(tags)

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
        return "#{filter.id}:#{filter.name}:#{filter.type}".toLowerCase()

    # Method used for convert plain array of tag strings to complete
    # js object that represent generic filter.
    plainTagsToObjectTags: (tags) ->
        return _.map tags, (item) ->
            return {id: item, name: item, type: "tags"}

    # Given a namespace and filter, check if specified filter
    # is selected or not.
    isFilterSelected: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}-filtering"
        filters = @gmStorage.get(key, [])
        return (filters.indexOf(@.filterToText(filterTag)) != -1)

    selectFilter: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}-filtering"

        filters = @gmStorage.get(key, [])
        filterKey = @.filterToText(filterTag)

        pos = filters.indexOf(filterKey)
        if pos == -1
            filters.push(filterKey)
            @gmStorage.set(key, filters)

    unselectFilter: (projectId, namespace, filterTag) ->
        key = "#{projectId}:#{namespace}-filtering"

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
        orderingNamespace = "#{projectId}:#{namespace}-ordering"
        hash = @.generateHash([projectId, orderingNamespace])
        @gmStorage.set(hash, ordering)

    # Namespaced method fro obtain stored ordering. This is a reverse
    # method of `setOrdering`.
    getOrdering: (projectId, namespace) ->
        orderingNamespace = "#{projectId}:#{namespace}-ordering"
        hash = @.generateHash([projectId, orderingNamespace])
        return @gmStorage.get(hash) or {}

    storeLastIssuesQueryParams: (projectId, namespace, params={}) ->
        ns = "#{projectId}:#{namespace}-queryparams"
        hash = @.generateHash([projectId, ns])
        @gmStorage.set(hash, params)

    getLastIssuesQueryParams: (projectId, namespace) ->
        ns = "#{projectId}:#{namespace}-queryparams"
        hash = @.generateHash([projectId, ns])
        return @gmStorage.get(hash) or {}

    makeIssuesQueryParams: (projectId, namespace, filters, extra={}) ->
        ordering = @.getOrdering(projectId, namespace)
        selectedFilters = @.getSelectedFiltersList(projectId, namespace, filters)

        params = {}
        params.page = if extra.page is undefined then 1 else extra.page

        for key, value of _.groupBy(selectedFilters, "type")
            params[key] = _.map(value, "id").join(",")

        if ordering.orderBy
            if ordering.isReverse
                params.order_by = "-#{ordering.orderBy}"
            else
                params.order_by = ordering.orderBy

        @.storeLastIssuesQueryParams(projectId, namespace, params)
        return params


module = angular.module("taiga.services.filters", ["gmStorage", "i18next"])
module.service("$gmFilters", FiltersService)
