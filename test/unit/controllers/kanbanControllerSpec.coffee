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

        beforeEach(inject(($rootScope, $controller, $httpBackend, $gmFilters) ->
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
            ctrl = $controller("KanbanController", {
                $scope: scope,
                $routeParams: routeParams,
                $gmFilters: gmFiltersMock
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

            httpBackend.expectPUT("#{APIURL}/userstories/3", {id: 3, test: "test1"}).respond(200, {id: 1, test: "test1"})
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
