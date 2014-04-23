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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


class FiltersService extends TaigaBaseService
    @.$inject = ["$rootScope", "$gmStorage", "$i18next"]

    constructor: (@rootScope, @gmStorage, @i18next) ->
        super()

    #####
    # Functions that generate filters for issues, because issues page
    # filtering works on server and it has distinct behavior than on
    # backlog or kanban
    #####

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
            assignedTo: @.generateFiltersFromUsersList(data.assigned_to, constants.users, "assigned_to")
        }

        return filters

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


    #####
    # Functions that generates filters for kanban/backlog.
    #####

    # User stories have tags attribute with plain
    # text tags, that should be converted on format
    # that taiga manages.
    generateTagsFromUserStoriesList: (userstories) ->
        plainTags = _.flatten(_.map(userstories, "tags"))
        tags = _.map _.countBy(plainTags), (value, key) ->
            return [key, value]

        return @.generateFiltersFromTagsList(tags)

    # Analyze a user stories list and generate a filters
    # list from it (depending on type parameter for field to analize)
    generatePersonFiltersFromUserStories: (userstories, constants, type) ->
        ids = _.map(userstories, type)

        data = _.map _.countBy(ids), (v,k) ->
            return [parseInt(k, 10) or null, v]

        return @.generateFiltersFromUsersList(data, constants, type)

    # Specific logic for kanban/backlog page that generates a complete
    # filters map from user stories list.
    generateFiltersForKanban: (userstories, constants) ->
        filters = {
            tags: @.generateTagsFromUserStoriesList(userstories)
            assignedTo: @.generatePersonFiltersFromUserStories(userstories, constants.users, "assigned_to")
        }

        return filters

    getFiltersForUserStory: (us) ->
        filters = [
            @.filterToText({id: us.assigned_to, type: "assigned_to"})
        ]

        tags = _.map(@.plainTagsToObjectTags(us.tags), @.filterToText)
        return _.union(filters, tags)


    #####
    # Generic util functions.
    #####

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
        return "#{filter.id}:#{filter.type}".toLowerCase()

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

module = angular.module("taiga.services.filters", ["gmStorage", "i18next"])
module.service("$gmFilters", FiltersService)
