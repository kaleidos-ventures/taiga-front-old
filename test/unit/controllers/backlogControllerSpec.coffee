describe "backlogController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.backlog"))

    describe "BacklogController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve()
                    return defered.promise
            }
            ctrl = $controller("BacklogController", {
                $scope: scope
                $routeParams: routeParams
                $modal: modalMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {
                project: 1
            })
            httpBackend.whenGET("#{APIURL}/projects/1/stats").respond(200)
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, {
                id: 1,
                members: []
                tags: "",
                list_of_milestones: [],
                roles: [],
                active_memberships: [],
                memberships: [],
                us_statuses: [],
                points: [],
                task_statuses: [],
                priorities: [],
                severities: [],
                issue_statuses: [],
                issue_types: [],
            })
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, [])

            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section issues", ->
            expect(ctrl.section).to.be.equal("backlog")

        it "should reload the stats on 'status:update' event emitted", ->
            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200)
            ctrl.scope.$emit "stats:update"
            httpBackend.flush()

        it "should set the percentage based on stats", ->
            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200, {
                closed_points: 10
                total_points: 50
            })
            ctrl.reloadStats()
            httpBackend.flush()
            expect(ctrl.scope.percentageBarCompleted).to.be.equal(20)

            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200, {
                closed_points: 10
                total_points: 0
            })
            ctrl.reloadStats()
            httpBackend.flush()
            expect(ctrl.scope.percentageBarCompleted).to.be.equal(0)

            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200, {
                closed_points: 55
                total_points: 50
            })
            ctrl.reloadStats()
            httpBackend.flush()
            expect(ctrl.scope.percentageBarCompleted).to.be.equal(100)

            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200)
            ctrl.reloadStats()
            httpBackend.flush()
            expect(ctrl.scope.percentageBarCompleted).to.be.equal(0)

        it "should set the sprintId on milestones:loaded signal emitted", ->
            ctrl.rootScope.sprintId = 0
            ctrl.scope.$emit "milestones:loaded", [{id: 1}, {id: 2}]
            expect(ctrl.rootScope.sprintId).to.be.equal(1)

            ctrl.rootScope.sprintId = 0
            ctrl.scope.$emit "milestones:loaded", []
            expect(ctrl.rootScope.sprintId).to.be.zero

    describe "BacklogUserStoriesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve()
                    return defered.promise
            }
            gmFiltersMock = {
                generateTagsFromUserStoriesList: ->
                    ["test1", "test2", "test3"]
                getSelectedFiltersList: ->
                    ["test2"]
                isFilterSelected: ->
                    true
                selectFilter: ->
                unselectFilter: ->
                plainTagsToObjectTags: $gmFilters.plainTagsToObjectTags
                filterToText: $gmFilters.filterToText
            }
            ctrl = $controller("BacklogUserStoriesController", {
                $scope: scope
                $modal: modalMock
                $gmFilters: gmFiltersMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should save milestones on milestones:loaded signal", ->
            ctrl.scope.$emit "milestones:loaded", [{test: "test"}]
            expect(ctrl.scope.milestones).to.be.deep.equal([{test: "test"}])

        it "should allow to recalculate stats (by emitting stats:updated)", ->
            sinon.spy(ctrl.scope, '$emit')
            ctrl.calculateStats()
            expect(ctrl.scope.$emit).have.been.calledWith("stats:update")

        it "should allow initialize the filters", ->
            ctrl.initializeFilters()
            expect(ctrl.filters).to.be.deep.equal({tags: ["test1", "test2", "test3"]})
            expect(ctrl.selectedFilters).to.be.deep.equal(["test2"])

        it "should allow to check if a filter is selected", ->
            expect(ctrl.isFilterSelected("test")).to.be.true

        it "should allow toggle a filter", ->
            ctrl.filterUsBySelectedTags = ->

            sinon.spy(ctrl.gmFilters, "selectFilter")
            sinon.spy(ctrl.gmFilters, "unselectFilter")
            sinon.spy(ctrl, "filterUsBySelectedTags")

            ctrl.selectedFilters = [{type: "test1", id: "test1"}, {type:"test2", id: "test2"}]

            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.selectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([{type: "test1", id: "test1"}, {type:"test2", id: "test2"}, {type: "test", id: "test"}])

            ctrl.selectedFilters = [{type: "test1", id: "test1"}, {type:"test2", id: "test2"}, {type: "test", id: "test"}]
            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.unselectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([{type: "test1", id: "test1"}, {type:"test2", id: "test2"}])

            expect(ctrl.filterUsBySelectedTags).have.been.called.twice

        it "should allow to filter uss by selected tags", ->
            ctrl.selectedFilters = []
            ctrl.scope.unassignedUs = [{id: 1}, {id: 2}]
            ctrl.filterUsBySelectedTags()
            expect(ctrl.scope.unassignedUs).to.be.deep.equal([{id: 1, __hidden: false}, {id: 2, __hidden: false}])

            ctrl.selectedFilters = [{type: "tags", id: "test2"}]
            ctrl.scope.unassignedUs = [{id: 1, tags: ["test1"]}, {id: 2, tags: ["test2"]}]
            ctrl.filterUsBySelectedTags()
            expect(ctrl.scope.unassignedUs).to.be.deep.equal([{id: 1, tags: ["test1"], __hidden: true}, {id: 2, tags: ["test2"], __hidden: false}])

        it "should allow to save resorted user stories", inject ($model) ->
            ctrl.scope.unassignedUs = _.map([{id: 1, order: 2}, {id: 2, order: 1}, {id: 3, order: 3}], (us) -> $model.make_model('userstories', us))

            httpBackend.expectPOST("http://localhost:8000/api/v1/userstories/bulk_update_order", {"bulkStories":[[1,0],[2,1],[3,2]]}).respond(200)
            promise = ctrl.resortUserStories()
            httpBackend.flush()
            promise.should.be.fulfilled

        it "should allow load the user stories", ->
            httpBackend.expectGET("http://localhost:8000/api/v1/userstories?milestone=null").respond(200)
            promise = ctrl.loadUserStories()
            httpBackend.flush()
            promise.should.be.fulfilled

            httpBackend.expectGET("http://localhost:8000/api/v1/userstories?milestone=null").respond(400)
            promise = ctrl.loadUserStories()
            httpBackend.flush()
            promise.should.be.rejected

        it "should allow to refresh the user stories", ->
            httpBackend.expectGET("http://localhost:8000/api/v1/userstories?milestone=null").respond(200)
            promise = ctrl.refreshBacklog()
            expect(ctrl.scope.refreshing).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled
            expect(ctrl.scope.refreshing).to.be.false

            httpBackend.expectGET("http://localhost:8000/api/v1/userstories?milestone=null").respond(400)
            promise = ctrl.refreshBacklog()
            expect(ctrl.scope.refreshing).to.be.true
            httpBackend.flush()
            promise.should.be.rejected
            expect(ctrl.scope.refreshing).to.be.false

        it "should allow to calculate story points", ->
            ctrl.scope.constants.points = []
            ctrl.scope.constants.points[1] = {value: 10}
            ctrl.scope.constants.points[2] = {value: 20}
            ctrl.scope.constants.points[3] = {}
            expect(ctrl.calculateStoryPoints()).to.be.equal(0)
            expect(ctrl.calculateStoryPoints([])).to.be.equal(0)
            expect(ctrl.calculateStoryPoints([{points:{1:1, 2:1}}])).to.be.equal(20)
            expect(ctrl.calculateStoryPoints([{points:{1:2, 2:2, 3:3}}])).to.be.equal(40)

        it "should allow to get the selected user stories", ->
            ctrl.scope.unassignedUs = [{id:1, selected: true}, {id:2, selected:false}]
            expect(ctrl.getSelectedUserStories()).to.be.deep.equal([{id:1, selected: true}])
            ctrl.scope.unassignedUs = []
            expect(ctrl.getSelectedUserStories()).to.be.deep.equal([])

        it "should allow to get the unselected user stories", ->
            ctrl.scope.unassignedUs = [{id:1, selected: true}, {id:2, selected:false}]
            expect(ctrl.getUnselectedUserStories()).to.be.deep.equal([{id:2, selected: false}])
            ctrl.scope.unassignedUs = []
            expect(ctrl.getUnselectedUserStories()).to.be.deep.equal([])

        it "should allow move the selected user stories to the current sprint", inject ($model) ->
            scope.milestones = [{id: 1, user_stories: []}, {id: 2, user_stories: []}]
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, order: 2, selected: true}, {id: 2, order: 1, selected: true}, {id: 3, order: 3, selected: false}],
                (us) -> $model.make_model('userstories', us)
            )
            ctrl.moveSelectedUserStoriesToCurrentSprint()
            expect(_.map(ctrl.scope.milestones[0].user_stories, (x) -> x.getAttrs())).to.be.deep.equal([{id: 1, order: 2, selected: true}, {id: 2, order: 1, selected: true}])
            expect(ctrl.scope.milestones[0].user_stories[0].milestone).to.be.equal(1)
            expect(ctrl.scope.milestones[0].user_stories[1].milestone).to.be.equal(1)
            expect(ctrl.scope.unassignedUs).to.have.length(1)

            scope.milestones = []
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, order: 2, selected: true}, {id: 2, order: 1, selected: true}, {id: 3, order: 3, selected: false}],
                (us) -> $model.make_model('userstories', us)
            )
            ctrl.moveSelectedUserStoriesToCurrentSprint()
            expect(ctrl.scope.unassignedUs).to.have.length(3)
