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

        it "should reload the stats on status:update event emitted", ->
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
            sinon.spy(ctrl.scope, "$emit")
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
            ctrl.scope.unassignedUs = _.map([{id: 1, order: 2}, {id: 2, order: 1}, {id: 3, order: 3}], (us) -> $model.make_model("userstories", us))

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
                [{id: 1, selected: true}, {id: 2, selected: true}, {id: 3, selected: false}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.moveSelectedUserStoriesToCurrentSprint()
            expect(_.map(ctrl.scope.milestones[0].user_stories, (x) -> x.getAttrs())).to.be.deep.equal([{id: 1, selected: true}, {id: 2, selected: true}])
            expect(ctrl.scope.milestones[0].user_stories[0].milestone).to.be.equal(1)
            expect(ctrl.scope.milestones[0].user_stories[1].milestone).to.be.equal(1)
            expect(ctrl.scope.unassignedUs).to.have.length(1)

            scope.milestones = []
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, order: 2, selected: true}, {id: 2, order: 1, selected: true}, {id: 3, order: 3, selected: false}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.moveSelectedUserStoriesToCurrentSprint()
            expect(ctrl.scope.unassignedUs).to.have.length(3)

        it "should recalc selected user stories and selected stories points", ->
            ctrl.scope.unassignedUs = [{id:1, selected: true, points: {1:1, 2:1}}, {id:2, selected:false, points: {1:2, 2:2, 3:3}}]
            ctrl.scope.selectedUserStories = []
            ctrl.scope.selectedStoryPoints = 0
            ctrl.scope.constants.points = []
            ctrl.scope.constants.points[1] = {value: 10}
            ctrl.scope.constants.points[2] = {value: 20}

            ctrl.changeUserStoriesSelection()
            expect(ctrl.scope.selectedUserStories).to.have.length(1)
            expect(ctrl.scope.selectedStoryPoints).to.be.equal(20)

        it "should allow to open a user story", ->
            sinon.spy(ctrl.location, "url")
            ctrl.openUserStory("test", 1)
            expect(ctrl.location.url).have.been.calledWith("/project/test/user-story/1")

        it "should allow to get the user story query params", ->
            expect(ctrl.getUserStoryQueryParams()).to.be.deep.equal({milestone: "null"})

        it "should allow to initialize the us form", ->
            expect(ctrl.initializeUsForm({test: "test"})).to.be.deep.equal({test: "test"})

            ctrl.scope.constants.computableRolesList = [{id: 1}, {id: 2}]
            ctrl.scope.project = {}
            ctrl.scope.project.default_points = 2
            ctrl.scope.project.default_us_status = 1
            ctrl.scope.projectId = 1
            expect(ctrl.initializeUsForm()).to.be.deep.equal({points: {1: 2, 2: 2}, project: 1, status: 1})

        it "should allow to open bulk user stories form", ->
            sinon.spy(ctrl.modal, "open")
            ctrl.loadUserStories = ->
            sinon.spy(ctrl, "loadUserStories")
            promise = ctrl.openBulkUserStoriesForm()

            expect(ctrl.modal.open).have.been.calledWith("bulk-user-stories-form", {})

            promise.should.be.fulfilled.then ->
                expect(ctrl.loadUserStories).have.been.called.once

        it "should allow to open create user stories form", ->
            ctrl.loadUserStories = ->
            ctrl.scope.constants.computableRolesList = [{id: 1}, {id: 2}]
            ctrl.scope.project = {}
            ctrl.scope.project.default_points = 2
            ctrl.scope.project.default_us_status = 1
            ctrl.scope.projectId = 1

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "loadUserStories")

            promise = ctrl.openCreateUserStoryForm()

            expect(ctrl.modal.open).have.been.calledWith("user-story-form", {us: {points: {1: 2, 2: 2}, project: 1, status: 1}, type: "create"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.loadUserStories).have.been.called.once

        it "should allow to open edit user stories form", ->
            ctrl.loadUserStories = ->

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "loadUserStories")

            promise = ctrl.openEditUserStoryForm({test: "test"})

            expect(ctrl.modal.open).have.been.calledWith("user-story-form", {us: {test: "test"}, type: "edit"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.loadUserStories).have.been.called.once

        it "should allow to remove a user story", inject ($model) ->
            ctrl.calculateStats = ->
            ctrl.generateTagList = ->
            ctrl.filterUsBySelectedTags = ->

            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl, "generateTagList")
            sinon.spy(ctrl, "filterUsBySelectedTags")

            ctrl.scope.unassignedUs = _.map([{id: 1, order: 2}, {id: 2, order: 1}, {id: 3, order: 3}], (us) -> $model.make_model("userstories", us))
            us = ctrl.scope.unassignedUs[0]

            httpBackend.expectDELETE("http://localhost:8000/api/v1/userstories/1").respond(200)

            promise = ctrl.removeUs(us)
            httpBackend.flush()

            promise.should.be.fulfilled. then ->
                expect(ctrl.scope.unassignedUs).to.have.length(2)
                expect(ctrl.calculateStats).have.been.called.once
                expect(ctrl.generateTagList).have.been.called.once
                expect(ctrl.filterUsBySelectedTags).have.been.called.once

        it "should allow to save user story points", inject ($model) ->
            ctrl.calculateStats = ->
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.scope, "$broadcast")
            us = $model.make_model("userstories", {id: 1, points: {}})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {points: {1: 5}}).respond(200)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.points[1]).to.be.equal(5)
                expect(us._moving).to.be.false
                expect(ctrl.calculateStats).have.been.called.once
                expect(ctrl.scope.$broadcast).have.been.calledWith("points:changed")

        it "should allow to save user story points (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, points: {}})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {points: {1: 5}}).respond(400)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once
                expect(us.points).to.be.deep.equal({})

        it "should allow to save user story status", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {status: 5}).respond(200)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.status).to.be.equal(5)
                expect(us._moving).to.be.false

        it "should allow to save user story status (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {status: 5}).respond(400)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us.status).to.be.equal(1)
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once

        it "should allow to move user story to the list of unassigned user stories", inject ($model) ->
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, milestone: null}, {id: 2, milestone: null}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.resortUserStories = ->
            sinon.spy(ctrl, "resortUserStories")

            us = $model.make_model("userstories", {id: 3, milestone: 1})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/3", {milestone: null}).respond(200)
            promise = ctrl.sortableOnAdd(us, 1)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.scope.unassignedUs, (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 1, milestone: null}, {id: 3, milestone: null}, {id: 2, milestone: null}]
                )
                expect(ctrl.resortUserStories).have.been.called.once

        it "should allow to move user story in the list of unassigned user stories", inject ($model) ->
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, milestone: null}, {id: 2, milestone: null}, {id: 3, milestone: null}],
                (us) -> $model.make_model("userstories", us)
            )
            uss = _.map(
                [{id: 3, milestone: null}, {id: 2, milestone: null}, {id: 1, milestone: null}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.resortUserStories = ->
            sinon.spy(ctrl, "resortUserStories")

            ctrl.sortableOnUpdate(uss)
            expect(
                _.map(ctrl.scope.unassignedUs, (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 3, milestone: null}, {id: 2, milestone: null}, {id: 1, milestone: null}]
            )
            expect(ctrl.resortUserStories).have.been.called.once

        it "should allow to remove user story from the list of unassigned user stories", inject ($model) ->
            ctrl.scope.unassignedUs = _.map(
                [{id: 1, milestone: null}, {id: 2, milestone: null}, {id: 3, milestone: null}],
                (us) -> $model.make_model("userstories", us)
            )

            ctrl.getSelectedUserStories = ->
                "test"
            sinon.spy(ctrl, "getSelectedUserStories")

            ctrl.calculateStoryPoints = ->
                10
            sinon.spy(ctrl, "calculateStoryPoints")

            ctrl.sortableOnRemove(ctrl.scope.unassignedUs[0])
            expect(
                _.map(ctrl.scope.unassignedUs, (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 2, milestone: null}, {id: 3, milestone: null}]
            )
            expect(ctrl.getSelectedUserStories).have.been.called.once
            expect(ctrl.calculateStoryPoints).have.been.called.once
            expect(ctrl.scope.selectedUserStories).to.be.equal("test")
            expect(ctrl.scope.selectedStoryPoints).to.be.equal(10)

    describe "BacklogUserStoryModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("BacklogUserStoryModalController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to load project tags", ->
            ctrl.scope.projectId = 1
            httpBackend.expectGET("http://localhost:8000/api/v1/projects/1/tags").respond(200, "test")
            promise = ctrl.loadProjectTags()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.projectTags).to.be.equal("test")

        it "should allow to get the tags list", ->
            ctrl.projectTags = undefined
            expect(ctrl.getTagsList()).to.be.deep.equal([])
            ctrl.projectTags = ["test"]
            expect(ctrl.getTagsList()).to.be.deep.equal(["test"])

        it "should allow to open the modal", inject ($q) ->
            ctrl.loadProjectTags = ->
            sinon.spy(ctrl, "loadProjectTags")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.scope.context = {us: {id:1, points: {2: 2}}}

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.form).to.be.deep.equal({id:1, points: {2: 2}})
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.calledWith("wiki:clean-previews")
            expect(ctrl.scope.$broadcast).have.been.called.twice

            ctrl.scope.form.points = {1: 2}
            expect(ctrl.scope.form).to.be.deep.equal({id:1, points: {1: 2}})

        it "should allow to save the form of the modal", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/userstories?", {test: "test"}).respond(200, {id: 1, test: "test"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal (on edit)", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = $model.make_model("userstories", {id: 3, test: "test"})
            ctrl.scope.form.test = "test1"

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/3", {test: "test1"}).respond(200, {id: 1, test: "test1"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal (on error)", ->
            sinon.spy(ctrl.scope, "$emit")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/userstories?", {test: "test"}).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.formOpened).to.be.true
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({test: "test"})

    describe "BacklogBulkUserStoriesModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("BacklogBulkUserStoriesModalController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to open the modal", inject ($q) ->
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            expect(ctrl.scope.form).to.be.deep.equal({})
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.called.once

        it "should allow to save the form of the modal", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/userstories/bulk_create", {test: "test"}).respond(200, [{id: 1, test: "test"}])
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal (on error)", ->
            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/userstories/bulk_create", {test: "test"}).respond(400, {})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected

    describe "BacklogMilestonesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("BacklogMilestonesController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should reload milestons on points:loaded signal", ->
            ctrl.calculateStats = ->
            sinon.spy(ctrl, "calculateStats")
            ctrl.rootScope.projectId = 1
            httpBackend.expectGET("http://localhost:8000/api/v1/milestones?project=1").respond(200, [{}, {}])
            ctrl.scope.$emit("points:loaded")
            httpBackend.flush()
            expect(ctrl.calculateStats).have.been.called.once

        it "should allow to calculate the stats", ->
            sinon.spy(ctrl.scope, "$emit")
            ctrl.calculateStats()
            expect(ctrl.scope.$emit).have.been.calledWith("stats:update")

        it "should allow to open a user story", ->
            sinon.spy(ctrl.location, "url")
            ctrl.openUserStory("test", 1)
            expect(ctrl.location.url).have.been.calledWith("/project/test/user-story/1")

        it "should allow to save a new milestone", inject ($model) ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.form = {id: 8, test: "test"}
            ctrl.scope.sprintFormOpened = true
            ctrl.scope.milestones = []

            httpBackend.expectPOST("http://localhost:8000/api/v1/milestones", {id: 8, test: "test"}).respond(200, {id: 8, test: "test"})
            promise = ctrl._sprintSubmit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.rootScope.sprintId).to.be.equal(8)
                expect(ctrl.scope.sprintFormOpened).to.be.false
                expect(ctrl.scope.form).to.be.deep.equal({})
                expect(ctrl.gmFlash.info).have.been.called.once

        it "should allow to edit a milestone", inject ($model) ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.form = $model.make_model("milestones", {id: 8, test: "test"})
            ctrl.scope.form.test = "test1"

            httpBackend.expectPATCH("http://localhost:8000/api/v1/milestones/8", {test: "test1"}).respond(200, {id: 8, test: "test1"})
            promise = ctrl._sprintSubmit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.sprintFormOpened).to.be.false
                expect(ctrl.scope.form).to.be.deep.equal({})
                expect(ctrl.gmFlash.info).have.been.called.once

        it "should allow to save the form of the modal (on error)", ->
            ctrl.scope.form = {id: 8, test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/milestones", {id: 8, test: "test"}).respond(400, {})
            promise = ctrl._sprintSubmit()
            httpBackend.flush()
            promise.should.be.rejected

    describe "BacklogMilestoneController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            scope.ml = {user_stories: []}
            ctrl = $controller("BacklogMilestoneController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to calculate total points of an us", ->
            ctrl.scope.constants.points = []
            ctrl.scope.constants.points[1] = {value: 10}
            ctrl.scope.constants.points[2] = {value: 20}
            expect(ctrl.calculateTotalPoints({points: {1: 1, 2: 2}})).to.be.equal(30)

        it "should allow to calculate stats", ->
            ctrl.scope.constants.points = []
            ctrl.scope.constants.points[1] = {value: 10}
            ctrl.scope.constants.points[2] = {value: 20}
            ctrl.scope.ml.user_stories = [
                {points: {1: 1}, is_closed: false},
                {points: {2: 2}, is_closed: true},
                {points: {1: 1, 2: 2}, is_closed: true}
            ]
            ctrl.calculateStats()
            expect(ctrl.scope.stats.total).to.be.equal(60)
            expect(ctrl.scope.stats.closed).to.be.equal(50)
            expect(ctrl.scope.stats.percentage).to.be.equal("83.3")

        it "should allow to normalize milestones", inject ($model) ->
            ctrl.scope.constants.points = []
            ctrl.scope.constants.points[1] = {value: 10}
            ctrl.scope.constants.points[2] = {value: 20}

            ctrl.scope.ml.user_stories = [
                $model.make_model("userstories", {id: 1, points: {1: 1}, is_closed: false, order: 2}),
                $model.make_model("userstories", {id: 2, points: {2: 2}, is_closed: true, order: 1}),
                $model.make_model("userstories", {id: 3, points: {1: 1, 2: 2}, is_closed: true, order: 0})
            ]
            ctrl.scope.ml.user_stories[0].is_closed = true

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {is_closed: true}).respond(200)
            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/userstories/bulk_update_order",
                {"bulkStories":[[1, 0],[2, 1],[3, 2]]}
            ).respond(200)
            promise = ctrl.normalizeMilestones()
            httpBackend.flush()
            promise.should.be.fulfilled

        it "should allow show edit form", ->
            ctrl.scope.editFormOpened = false
            ctrl.showEditForm()
            expect(ctrl.scope.editFormOpened).to.be.true

        it "should allow toggle view uss", ->
            ctrl.scope.viewUSs = false
            ctrl.toggleViewUSs()
            expect(ctrl.scope.viewUSs).to.be.true
            ctrl.toggleViewUSs()
            expect(ctrl.scope.viewUSs).to.be.false

        it "should allow to save the form of the mileston", inject ($model) ->
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.ml = $model.make_model("milestones", {id: 1, test: "test"})
            ctrl.scope.ml.test = "test1"

            httpBackend.expectPATCH("http://localhost:8000/api/v1/milestones/1", {test: "test1"}).respond(200)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.editFormOpened).to.be.false
                expect(ctrl.gmFlash.info).have.been.called.once

        it "should allow to save the form of the modal (on error)", inject ($model) ->
            ctrl.scope.ml = $model.make_model("milestones", {id: 1, test: "test"})
            ctrl.scope.ml.test = "test1"

            httpBackend.expectPATCH("http://localhost:8000/api/v1/milestones/1", {test: "test1"}).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected

        it "should allow to close the edit form", inject ($model) ->
            ctrl.scope.editFormOpened = true
            ctrl.scope.ml = $model.make_model("milestones", {id: 1, test: "test"})
            ctrl.scope.ml.test = "test1"
            ctrl.closeEditForm()
            expect(ctrl.scope.editFormOpened).to.be.false
            expect(ctrl.scope.ml.test).to.be.equal("test")

        it "should allow to move user story to the list of milestone user stories", inject ($model) ->
            ctrl.scope.ml = {}
            ctrl.scope.ml.id = 1
            ctrl.scope.ml.user_stories = _.map(
                [{id: 1, milestone: 1}, {id: 2, milestone: 1}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.normalizeMilestones = ->
            sinon.spy(ctrl, "normalizeMilestones")

            us = $model.make_model("userstories", {id: 3, milestone: 2})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/3", {milestone: 1}).respond(200)
            promise = ctrl.sortableOnAdd(us, 1)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.scope.ml.user_stories, (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 1, milestone: 1}, {id: 3, milestone: 1}, {id: 2, milestone: 1}]
                )
                expect(ctrl.normalizeMilestones).have.been.called.once

        it "should allow to move user story in the list of milestone user stories", inject ($model) ->
            ctrl.scope.ml = {}
            ctrl.scope.ml.user_stories = _.map(
                [{id: 1, milestone: 1}, {id: 2, milestone: 1}, {id: 3, milestone: 1}],
                (us) -> $model.make_model("userstories", us)
            )
            uss = _.map(
                [{id: 3, milestone: 1}, {id: 2, milestone: 1}, {id: 1, milestone: 1}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.normalizeMilestones = ->
            sinon.spy(ctrl, "normalizeMilestones")

            ctrl.sortableOnUpdate(uss)
            expect(
                _.map(ctrl.scope.ml.user_stories, (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 3, milestone: 1}, {id: 2, milestone: 1}, {id: 1, milestone: 1}]
            )
            expect(ctrl.normalizeMilestones).have.been.called.once

        it "should allow to remove user story from the list of milestone user stories", inject ($model) ->
            ctrl.scope.ml = {}
            ctrl.scope.ml.user_stories = _.map(
                [{id: 1, milestone: 1}, {id: 2, milestone: 1}, {id: 3, milestone: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            ctrl.sortableOnRemove(ctrl.scope.ml.user_stories[0])
            expect(
                _.map(ctrl.scope.ml.user_stories, (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 2, milestone: 1}, {id: 3, milestone: 1}]
            )
