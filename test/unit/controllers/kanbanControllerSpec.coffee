FIXTURES = {
    project: {
        id: 1,
        domain: 1,
        name: "Project Example 0",
        slug: "project-example-0",
        description: "Project example 0 description",
        created_date: "2013-12-20T09:53:46.361Z",
        modified_date: "2013-12-20T09:53:59.027Z",
        owner: 2,
        public: true,
        total_milestones: 5,
        total_story_points: 1062.0,
        default_points: 1,
        default_us_status: 1,
        default_task_status: 1,
        default_priority: 2,
        default_severity: 3,
        default_issue_status: 1,
        default_issue_type: 1,
        default_question_status: 1,
        members: [1, 2]
        tags: "",
        list_of_milestones: [
            {
                id: 1
                name: "Sprint 1",
                finish_date: "2014-02-13",
                closed: true,
                total_points: {},
                closed_points: {},
                client_increment_points: {},
                team_increment_points: {}
            }
        ],
        roles: [],
        active_memberships: [],
        memberships: [],
        us_statuses: [],
        points: [],
        task_statuses: [
            {
                id: 1,
                name: "New",
                order: 1,
                is_closed: false,
                project: 1
            },
            {
                id: 2,
                name: "In progress",
                order: 2,
                is_closed: false,
                color: "#ff9900",
                project: 1
            },
            {
                id: 3,
                name: "Ready for test",
                order: 3,
                is_closed: true,
                color: "#ffcc00",
                project: 1
            },
            {
                id: 4,
                name: "Closed",
                order: 4,
                is_closed: true,
                color: "#669900",
                project: 1
            },
            {
                id: 5,
                name: "Needs Info",
                order: 5,
                is_closed: false,
                color: "#999999",
                project: 1
            }
        ],
        priorities: [],
        severities: [],
        issue_statuses: [],
        issue_types: [],
    }
    users: [
        {
            id: 1,
            username: "admin",
            first_name: "",
            last_name: "",
            full_name: "admin",
            email: "admin@taiga.io",
            is_active: true,
        },
        {
            id: 2,
            username: "user-0",
            first_name: "Marina",
            last_name: "Medina",
            full_name: "Marina Medina",
            email: "ducimus@maiores.net",
            is_active: true,
        }
    ]
    permissions: [
        {
            id: 90,
            name: "Can add issue",
            codename: "add_issue"
        },
        {
            id: 91,
            name: "Can change issue",
            codename: "change_issue"
        }
    ]
    roles: [
        {
            id: 4,
            name: "Back",
            permissions: [90, 91],
            computable: true,
            project: 1,
            order: 40
        },
        {
            id: 5,
            name: "Product Owner",
            permissions: [91],
            computable: false,
            project: 1,
            order: 50
        }
    ]
    userstories: [
        {
            id: 96
            project: 4
            order: 100
            ref: 1
            status: 7
            points: {19:37, 20:37, 21:37, 22:37}
            total_points: 0
            assigned_to: 2
            subject: "Create the user model"
            tags: ["test1", "test2", "test3"]
        }
    ]
}


describe "kanbanController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.kanban"))

    describe "KanbanController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $gmFilters, $q) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            gmFiltersMock = {
                generateTagsFromUserStoriesList: ->
                    ["test1", "test2", "test3"]
                generatePersonFiltersFromUserStories: ->
                    [1]
                getSelectedFiltersList: ->
                    ["test2"]
                isFilterSelected: (p, n, t)->
                    return t is "test2"
                selectFilter: ->
                unselectFilter: ->
                plainTagsToObjectTags: $gmFilters.plainTagsToObjectTags
                filterToText: $gmFilters.filterToText
                generateFiltersForKanban: $gmFilters.generateFiltersForKanban
                getFiltersForUserStory: $gmFilters.getFiltersForUserStory
            }
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve()
                    return defered.promise
            }
            ctrl = $controller("KanbanController", {
                $scope: scope,
                $routeParams: routeParams,
                $gmFilters: gmFiltersMock,
                $modal: modalMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("#{APIURL}/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, FIXTURES.users)
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, FIXTURES.roles)
            httpBackend.whenGET("#{APIURL}/userstories?project=1").respond(200, FIXTURES.userstories)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section kanban", ->
            expect(ctrl.section).to.be.equal("kanban")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.kanban")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should allow initialize the filters", ->
            ctrl.initializeFilters()
            expect(ctrl.filters).to.be.deep.equal({tags: ["test1", "test2", "test3"], assignedTo: [1]})
            expect(ctrl.selectedFilters).to.be.deep.equal(["test2"])

        it "should allow to check if a filter is selected", ->
            expect(ctrl.isFilterSelected("test2")).to.be.true
            expect(ctrl.isFilterSelected("test6")).to.be.false

        it "should allow toggle a filter", ->
            ctrl.filterUserStories = ->

            sinon.spy(ctrl.gmFilters, "selectFilter")
            sinon.spy(ctrl.gmFilters, "unselectFilter")
            sinon.spy(ctrl, "filterUserStories")

            ctrl.selectedFilters = [
                {type: "test1", id: "test1"},
                {type:"test2", id: "test2"}
            ]

            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.selectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([
                {type: "test1", id: "test1"},
                {type:"test2", id: "test2"},
                {type: "test", id: "test"}
            ])

            ctrl.selectedFilters = [
                {type: "test1", id: "test1"},
                {type:"test2", id: "test2"},
                {type: "test", id: "test"}
            ]
            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.unselectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([
                {type: "test1", id: "test1"},
                {type:"test2", id: "test2"}
            ])

            expect(ctrl.filterUserStories).have.been.called.twice

        it "should allow to re-sort uss", inject ($model)->
            ctrl.uss = []
            ctrl.uss[1] = _.map(
                [{id: 1, status: 1, order: 0}, {id: 4, status: 1, order: 1}],
                (us) -> $model.make_model("userstories", us)
            )
            ctrl.uss[2] = _.map(
                [{id: 2, status: 2, order: 0}, {id: 3, status: 2, order: 2}, {id: 5, status: 2, order: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            httpBackend.expectPOST("#{APIURL}/userstories/bulk_update_order", {
                    projectId: 1, bulkStories: [[1,0], [4,1]]}).respond(200)
            ctrl.resortUserStories(1)
            httpBackend.flush()
            expect(
                _.map(ctrl.uss[1], (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 1, status: 1, order: 0}, {id: 4, status: 1, order: 1}]
            )

            httpBackend.expectPOST("#{APIURL}/userstories/bulk_update_order", {
                    projectId: 1, bulkStories: [[2,0],[3,1],[5,2]]}).respond(200)
            ctrl.resortUserStories(2)
            httpBackend.flush()
            expect(
                _.map(ctrl.uss[2], (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 2, status: 2, order: 0}, {id: 3, status: 2, order: 1}, {id: 5, status: 2, order: 2}],
            )

        it "should allow to filter uss by selected tags", ->
            ctrl.selectedFilters = []
            ctrl.scope.userstories = [
                {id: 1, tags: ["test1"], assigned_to: 1},
                {id: 2, tags: ["test2"], assigned_to: 2}
            ]
            ctrl.filterUserStories()
            expect(ctrl.scope.userstories).to.be.deep.equal([
                {id: 1, tags: ["test1"], assigned_to: 1, __hidden: false},
                {id: 2, tags: ["test2"], assigned_to: 2, __hidden: false}
            ])

            ctrl.selectedFilters = [{type: "tags", id: "test2"}]
            ctrl.scope.userstories = [
                {id: 1, tags: ["test1"], assigned_to: 1},
                {id: 2, tags: ["test2"], assigned_to: 2}
            ]
            ctrl.filterUserStories()
            expect(ctrl.scope.userstories).to.be.deep.equal([
                {id: 1, tags: ["test1"], assigned_to: 1, __hidden: true},
                {id: 2, tags: ["test2"], assigned_to: 2, __hidden: false}
            ])

        it "allow to prepare uss for render", ->
            ctrl.scope.constants.usStatusesList = [
                {id: 1},
                {id: 2}
            ]
            ctrl.scope.userstories = [
                {id: 1, status: 1},
                {id: 2, status: 2},
                {id: 3, status: 2},
                {id: 4, status: 1},
                {id: 5, status: 2},
            ]

            ctrl.prepareForRenderUserStories()

            expect(ctrl.uss[1]).to.be.deep.equal([
                {id: 1, status: 1},
                {id: 4, status: 1}
            ])
            expect(ctrl.uss[2]).to.be.deep.equal([
                {id: 2, status: 2},
                {id: 3, status: 2},
                {id: 5, status: 2}
            ])

        it "shouldn allow to formatted the uss", ->
            sinon.spy(ctrl, "filterUserStories")
            sinon.spy(ctrl, "prepareForRenderUserStories")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.formatUserStories()

            expect(ctrl.filterUserStories).have.been.called.once
            expect(ctrl.prepareForRenderUserStories).have.been.called.once
            expect(ctrl.scope.$broadcast).have.been.calledWith("kanban:redraw")
        it "should allow to open create user stories form", ->
            ctrl.formatUserStories = ->
            ctrl.scope.constants.computableRolesList = [{id: 1}, {id: 2}]
            ctrl.scope.project = {}
            ctrl.scope.project.default_points = 2
            ctrl.scope.project.default_us_status = 1
            ctrl.scope.projectId = 1

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "formatUserStories")

            promise = ctrl.openCreateUsForm(1)

            expect(ctrl.modal.open).have.been.calledWith("us-form", {us: {
                    points: {1: 2, 2: 2}, project: 1, status: 1}, type: "create"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStories).have.been.called.once

        it "should allow to open edit user stories form", ->
            ctrl.formatUserStories = ->

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "formatUserStories")

            promise = ctrl.openEditUsForm({test: "test"})

            expect(ctrl.modal.open).have.been.calledWith("us-form", {us: {test: "test"}, type: "edit"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStories).have.been.called.once


        it "should allow to save user story points", inject ($model) ->
            sinon.spy(ctrl.scope, "$broadcast")
            us = $model.make_model("userstories", {id: 1, points: {}})

            httpBackend.expectPATCH("#{APIURL}/userstories/1", {points: {1: 5}}).respond(200)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.points[1]).to.be.equal(5)
                expect(us._moving).to.be.false
                expect(ctrl.scope.$broadcast).have.been.calledWith("points:changed")

        it "should allow to save user story points (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, points: {}})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("#{APIURL}/userstories/1", {points: {1: 5}}).respond(400)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once
                expect(us.points).to.be.deep.equal({})

        it "should allow to save user story status", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})

            httpBackend.expectPATCH("#{APIURL}/userstories/1", {status: 5}).respond(200)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.status).to.be.equal(5)
                expect(us._moving).to.be.false

        it "should allow to save user story status (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("#{APIURL}/userstories/1", {status: 5}).respond(400)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us.status).to.be.equal(1)
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once

        it "should allow to sort a status colunm when added one us if backlog is deactivate", inject ($model) ->
            ctrl.scope.project.is_backlog_activated = false
            sortableScope = {status: {id: 1}}

            ctrl.resortUserStories = ->
            sinon.spy(ctrl, "resortUserStories")

            ctrl.uss = []
            ctrl.uss[1] = _.map(
                [{id: 1, status: 1}, {id: 2, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            us = $model.make_model("userstories", {id: 3, status: 2})
            httpBackend.expectPATCH("#{APIURL}/userstories/3", {status: 1}).respond(200)

            promise = ctrl.sortableOnAdd(us, 3, sortableScope)
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.uss[1], (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 1, status: 1}, {id: 2, status: 1}, {id: 3, status: 1}]
                )
                expect(ctrl.resortUserStories).have.been.called.once

        it "shouldn't sort a status colunm when added one if backlog is activate", inject ($model) ->
            ctrl.scope.project.is_backlog_activated = true
            sortableScope = {status: {id: 1}}

            ctrl.resortUserStories = ->
            sinon.spy(ctrl, "resortUserStories")

            ctrl.uss = []
            ctrl.uss[1] = _.map(
                [{id: 1, status: 1}, {id: 2, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            us = $model.make_model("userstories", {id: 3, status: 2})
            httpBackend.expectPATCH("#{APIURL}/userstories/3", {status: 1}).respond(200)

            promise = ctrl.sortableOnAdd(us, 3, sortableScope)
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.uss[1], (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 3, status: 1}, {id: 1, status: 1}, {id: 2, status: 1}]
                )
                expect(ctrl.resortUserStories).have.not.been.called

        it "should allow to move us in a status colum if backlog is deactivate", inject ($model, $q) ->
            ctrl.scope.project.is_backlog_activated = false
            sortableScope = {status: {id: 1}}

            sinon.spy(ctrl, "resortUserStories")
            sinon.spy(ctrl, "formatUserStories")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.uss = []
            ctrl.uss[1] = _.map(
                [{id: 1, status: 1}, {id: 2, status: 1}, {id: 3, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )
            uss = _.map(
                [{id: 3, status: 1}, {id: 1, status: 1}, {id: 2, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            httpBackend.expectPOST("#{APIURL}/userstories/bulk_update_order", {
                    projectId: 1, bulkStories: [[3,0], [1,1], [2,2]]}).respond(200)

            promise = ctrl.sortableOnUpdate(uss, sortableScope)
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.uss[1], (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 3, status: 1}, {id: 1, status: 1}, {id: 2, status: 1}]
                )
                expect(ctrl.formatUserStories).have.not.been.called
                expect(ctrl.resortUserStories).have.been.called.once
                expect(ctrl.scope.$broadcast).have.been.calledWith("wipline:redraw")

        it "shouldn't allow to move us in a status colum if backlog is activate", inject ($model, $q) ->
            ctrl.scope.constants.usStatusesList = [{id: 1}]
            ctrl.scope.project.is_backlog_activated = true
            sortableScope = {status: {id: 1}}

            sinon.spy(ctrl, "resortUserStories")
            sinon.spy(ctrl, "formatUserStories")
            sinon.spy(ctrl.scope, "$broadcast")

            uss = _.map(
                [{id: 3, status: 1}, {id: 1, status: 1}, {id: 2, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            httpBackend.expectGET("#{APIURL}/userstories?project=1").respond(200,
                    [{id: 1, status: 1}, {id: 2, status: 1}, {id: 3, status: 1}])

            promise = ctrl.sortableOnUpdate(uss, sortableScope)
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.uss[1], (us) -> us.getAttrs())
                ).to.be.deep.equal(
                    [{id: 1, status: 1}, {id: 2, status: 1}, {id: 3, status: 1}]
                )
                expect(ctrl.formatUserStories).have.been.called.once
                expect(ctrl.resortUserStories).have.not.been.called
                expect(ctrl.scope.$broadcast).have.been.calledWith("wipline:redraw")

        it "should allow to remove and us of a status colum of the kanban", inject ($model) ->
            sortableScope = {status: {id: 1}}

            ctrl.uss = []
            ctrl.uss[1] = _.map(
                [{id: 1, status: 1}, {id: 2, status: 1}, {id: 3, status: 1}],
                (us) -> $model.make_model("userstories", us)
            )

            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.sortableOnRemove(ctrl.uss[1][0], sortableScope)
            expect(
                _.map(ctrl.uss[1], (us) -> us.getAttrs())
            ).to.be.deep.equal(
                [{id: 2, status: 1}, {id: 3, status: 1}],
            )

            expect(ctrl.scope.$broadcast).have.been.calledWith("wipline:redraw")


    describe "KanbanUsModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("KanbanUsModalController", {
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
            httpBackend.expectGET("#{APIURL}/projects/1/tags").respond(200, "test")
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

            httpBackend.expectPOST("#{APIURL}/userstories?", {test: "test"}).respond(200, {id: 1, test: "test"})
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

            httpBackend.expectPUT("#{APIURL}/userstories/3", {id: 3, test: "test1"}).respond(
                                                                  200, {id: 1, test: "test1"})
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

            httpBackend.expectPOST("#{APIURL}/userstories?", {test: "test"}).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.formOpened).to.be.true
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({test: "test"})


    describe "KanbanUsController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("KanbanUsController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to change the assigned of a US on success", inject ($model) ->
            us = $model.make_model("userstories", {id: 3, test: "test", assigned_to: 1})
            newAssigned = 3

            sinon.spy(us, "revert")
            httpBackend.expectPATCH("#{APIURL}/userstories/#{us.id}", {assigned_to: newAssigned}).respond(
                                                                                               200, "ok")

            ctrl.updateUsAssignation(us, newAssigned)
            httpBackend.flush()

            expect(us.revert).have.not.been.called
            expect(us.assigned_to).to.be.equal(newAssigned)

        it "should allow to change the assigned of a US on success", inject ($model) ->
            us = $model.make_model("userstories", {id: 3, test: "test", assigned_to: 1})
            newAssigned = 3

            sinon.spy(us, "revert")
            httpBackend.expectPATCH("#{APIURL}/userstories/#{us.id}", {assigned_to: newAssigned}).respond(
                                                                                              400, "error")

            ctrl.updateUsAssignation(us, newAssigned)
            httpBackend.flush()

            expect(us.revert).have.been.calledOnce
            expect(us.assigned_to).to.be.equal(1)

        it "should go to the US detail page", ->
            sinon.spy(ctrl.location, "url")
            projectSlug = "test"
            usRef = "1"

            ctrl.openUs(projectSlug, usRef)
            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/user-story/1")
