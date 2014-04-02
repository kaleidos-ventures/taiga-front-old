beforeEach(module('taiga.services.filters'))

describe "$gmFilters", ->

    $rootScope = null
    $gmFilters = null

    beforeEach(inject((_$rootScope_, _$gmFilters_) ->
        $rootScope = _$rootScope_
        $gmFilters = _$gmFilters_
    ))


    it "Check if filter is selected",  ->
        tag = {id:1, name: "foo", type: "bar"}
        $gmFilters.selectFilter(1, "ns1", tag)
        expect($gmFilters.isFilterSelected(1, "ns1", tag)).to.be.true

    it "Check unselect filter", ->
        tag = {id:1, name: "foo", type: "bar"}
        $gmFilters.selectFilter(1, "ns1", tag)
        $gmFilters.unselectFilter(1, "ns1", tag)

        expect($gmFilters.isFilterSelected(1, "ns1", tag)).to.be.false

    it "Convert tag to key as text", ->
        tag = {id:1, name: "foo", type: "bar"}
        expect($gmFilters.filterToText(tag)).to.be.equal("1:bar")

    it "Get selected filters", ->
        tag1 = {id:1, name: "foo1", type: "bar"}
        tag2 = {id:2, name: "foo2", type: "bar"}

        $gmFilters.selectFilter(1, "ns1", tag1)
        $gmFilters.selectFilter(1, "ns1", tag2)

        filtersData = {
            bar: [{id: 1, name: "foo1", type: "bar"},
                  {id: 2, name: "foo2", type: "bar"}]
        }

        selected = $gmFilters.getSelectedFiltersList(1, "ns1", filtersData)
        expect(selected.length).to.be.equal(2)

    it "Generate filters from generic list", ->
        constants = {
            1: {name: "Foo"}
            2: {name: "Bar"}
        }

        type = "footype"
        data = [[1,5], [2,6]]

        result = $gmFilters.generateFiltersFromGenericList(data, constants, type)

        expect(result.length).to.be.equal(2)
        expect(result[0].id).to.be.equal(1)
        expect(result[0].count).to.be.equal(5)
        expect(result[0].type).to.be.equal(type)

    it "Generate filters from tags list",  ->
        data = [["tag1",5], ["tag2",6]]
        result = $gmFilters.generateFiltersFromTagsList(data)

        expect(result.length).to.be.equal(2)
        expect(result[0].id).to.be.equal("tag1")
        expect(result[0].count).to.be.equal(5)
        expect(result[0].type).to.be.equal("tags")

    it "Generate filters from users list", ->
        constants = {
            1: {name: "Foo"}
            2: {name: "Bar"}
        }

        type = "users"
        data = [[ null, 5], [2, 6]]

        result = $gmFilters.generateFiltersFromUsersList(data, constants, type)

        expect(result.length).to.be.equal(2)
        expect(result[1].id).to.be.equal("null")
        expect(result[1].count).to.be.equal(5)
        expect(result[1].type).to.be.equal(type)

    it "Store/Retrieve ordering", ->
        $gmFilters.setOrdering(1, "ns", {orderBy: "owner"})
        result = $gmFilters.getOrdering(1, "ns")
        expect(result.orderBy).to.be.equal("owner")

    it "Get Filters for user story", ->
        us = {
            id: 1
            assigned_to: 2,
            tags: ["foo", "bar"]
        }

        filters = $gmFilters.getFiltersForUserStory(us)
        expect(filters.length).to.be.equal(3)

    it "Generate filters for kanban", ->
        constants = {
            users: {
                1: {name: "Foo"}
                2: {name: "Bar"}
            }
        }

        userstories = _.map _.range(3), (i) ->
            return {
                id: i,
                assigned_to: i,
                tags: ["foo#{i}", "bar#{i}"]
            }

        filters = $gmFilters.generateFiltersForKanban(userstories, constants)
        expect(filters.tags.length).to.be.equal(6)
        expect(filters.assignedTo.length).to.be.equal(3)

    it "Generates filters for issues", ->
        constants = {
            users: {
                1: {name: "Foo"}
                2: {name: "Bar"}
            }
        }

        data = {
            tags: [ ["foo", 1], ["bar", 1]]
            assigned_to: [[1,1], [2,2]]
        }

        filters = $gmFilters.generateFiltersForIssues(data, constants)
        expect(filters.tags.length).to.be.equal(2)
        expect(filters.assignedTo.length).to.be.equal(2)

    it "Generate color for text", ->
        color = $gmFilters.getColorForText("foo")
        expect(color).to.be.equal("#036e47")

    it "Store/Restore params", ->
        params = {order_by: "status"}

        $gmFilters.storeLastIssuesQueryParams(1, "issues", params)
        result = $gmFilters.getLastIssuesQueryParams(1, "issues")

        expect(result.order_by).to.be.equal(params.order_by)

    it "Make issues query params", ->
        constants = {
            users: {
                1: {name: "Foo"}
                2: {name: "Bar"}
            }
        }

        data = {
            tags: [ ["foo", 1], ["bar", 1]]
            assigned_to: [[1,1], [2,2]]
        }

        filters = $gmFilters.generateFiltersForIssues(data, constants)
        tag = {id:"foo", name: "foo", type: "tags"}

        $gmFilters.selectFilter(1, "ns", tag)

        params = $gmFilters.makeIssuesQueryParams(1, "ns", filters)
        expect(params.tags).to.be.equal("foo")
        expect(params.page).to.be.equal(1)
