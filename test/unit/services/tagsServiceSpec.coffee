describe 'tagsService', ->
    rootScope = null

    beforeEach(module('taiga.services.tags'))

    describe "$gmFilters", ->
        it "Check if filter is selected", inject(($gmFilters) ->
            tag = {id:1, name: "foo", type: "bar"}
            $gmFilters.selectFilter(1, "ns1", tag)
            expect($gmFilters.isFilterSelected(1, "ns1", tag)).to.be.true
        )

        it "Check unselect filter", inject(($gmFilters) ->
            tag = {id:1, name: "foo", type: "bar"}
            $gmFilters.selectFilter(1, "ns1", tag)
            $gmFilters.unselectFilter(1, "ns1", tag)

            expect($gmFilters.isFilterSelected(1, "ns1", tag)).to.be.false
        )

        it "Convert tag to key as text", inject(($gmFilters) ->
            tag = {id:1, name: "foo", type: "bar"}
            expect($gmFilters.filterToText(tag)).to.be.equal("1:foo:bar")
        )

        it "Get selected filters", inject(($gmFilters) ->
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
        )

        it "Generate filters from generic list", inject(($gmFilters) ->
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
        )

        it "Generate filters from tags list", inject(($gmFilters) ->
            data = [["tag1",5], ["tag2",6]]
            result = $gmFilters.generateFiltersFromTagsList(data)

            expect(result.length).to.be.equal(2)
            expect(result[0].id).to.be.equal("tag1")
            expect(result[0].count).to.be.equal(5)
            expect(result[0].type).to.be.equal("tags")
        )

        it "Generate filters from users list", inject(($gmFilters) ->
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
        )

        it "Store/Retrieve ordering", inject(($gmFilters) ->
            $gmFilters.setOrdering(1, "ns", {orderBy: "owner"})
            result = $gmFilters.getOrdering(1, "ns")
            expect(result.orderBy).to.be.equal("owner")
        )
