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
        members: []
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
            permissions: [90, 91],
            computable: false,
            project: 1,
            order: 50
        }
    ]
}

describe "projectsController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.project"))

    describe "ProjectListController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            ctrl = $controller("ProjectListController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET(APIURL+"/projects").respond(200, [
                {name: "test proj 1", slug: "test-proj-1"},
                {name: "test proj 2", slug: "test-proj-2"}
            ])
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("projects")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.dashboard")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should have the project list", ->
            expect(ctrl.scope.projects).to.be.lengthOf(2)
            expect(ctrl.scope.projects[0].slug).to.be.equal("test-proj-1")
            expect(ctrl.scope.projects[1].slug).to.be.equal("test-proj-2")

    describe "ShowProjectsController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            ctrl = $controller("ShowProjectsController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have the project list when call showProjects", ->
            httpBackend.expectGET(APIURL+"/projects").respond(200, [{name: "test proj 1", slug: "test-proj-1"},
                                                                    {name: "test proj 2", slug: "test-proj-2"}])
            ctrl.scope.showProjects()
            httpBackend.flush()

            expect(ctrl.scope.myProjects).to.be.lengthOf(2)
            expect(ctrl.scope.myProjects[0].slug).to.be.equal("test-proj-1")
            expect(ctrl.scope.myProjects[1].slug).to.be.equal("test-proj-2")

        it "should have an empty project list when call showProjects and ther server have no projects", ->
            httpBackend.expectGET(APIURL+"/projects").respond(400, [])
            ctrl.scope.showProjects()
            httpBackend.flush()

            expect(ctrl.scope.myProjects).to.be.lengthOf(0)

    describe "ProjecAdminMainController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            gmFlashMock = {
                info: (text) ->
            }
            ctrl = $controller("ProjectAdminMainController", {
                $scope: scope,
                $routeParams: routeParams,
                $gmFlash: gmFlashMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.whenPATCH("#{APIURL}/projects/1", {name:"New name"}).respond(
                                                             202, {detail: "success"})
            httpBackend.whenPATCH("#{APIURL}/projects/1", {total_milestones: "Error"}).respond(
                                                                         400, {detail: "error"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("admin")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.admin-panel")

        it "should change the location", ->
            sinon.spy(ctrl.location, "url")

            ctrl.goTo("main")

            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/admin/main")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should be actived", ->
            expect(ctrl.isActive("main")).to.be.true

        it "should show a flash message when submitted with success", ->
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.project.name = "New name"
            ctrl.submit()
            httpBackend.flush()

            ctrl.gmFlash.info.should.have.been.calledOnce
            expect(ctrl.scope.checksleyErrors).to.be.undefined

        it "should show an error message when submitted with errors", ->
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.project.total_milestones = "Error"
            ctrl.submit()
            httpBackend.flush()

            ctrl.gmFlash.info.should.have.not.been.called
            expect(ctrl.scope.checksleyErrors.detail).to.be.equal("error")


    describe "ProjecAdminValuesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            ctrl = $controller("ProjectAdminValuesController", {
                $scope: scope,
                $routeParams: routeParams,
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("admin")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.admin-panel")

        it "should change the location", ->
            sinon.spy(ctrl.location, "url")

            ctrl.goTo("values")

            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/admin/values")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should be actived", ->
            expect(ctrl.isActive("values")).to.be.true


    describe "ProjecAdminMilestonesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("ProjectAdminMilestonesController", {
                $scope: scope,
                $routeParams: routeParams,
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("admin")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.admin-panel")

        it "should change the location", ->
            sinon.spy(ctrl.location, "url")

            ctrl.goTo("milestones")

            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/admin/milestones")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should be actived", ->
            expect(ctrl.isActive("milestones")).to.be.true

        it "should allow to delete a milestone", ->
            milestone = ctrl.scope.project.list_of_milestones[0]
            newProject = _.clone(FIXTURES.project, true)
            newProject.list_of_milestones = []

            httpBackend.expectDELETE("#{APIURL}/milestones/#{milestone.id}").respond(200)
            httpBackend.expectGET("#{APIURL}/projects/1?").respond(200, newProject)

            promise = ctrl.deleteMilestone(milestone)
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.project.list_of_milestones).to.be.lengthOf(0)


    describe "ProjecAdminMembershipsController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            ctrl = $controller("ProjectAdminMembershipsController", {
                $scope: scope,
                $routeParams: routeParams,
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, FIXTURES.users)
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, FIXTURES.roles)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("admin")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.admin-panel")

        it "should change the location", ->
            sinon.spy(ctrl.location, "url")

            ctrl.goTo("memberships")

            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/admin/memberships")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should be actived", ->
            expect(ctrl.isActive("memberships")).to.be.true


    describe "ProjecAdminRolesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
            }
            ctrl = $controller("ProjectAdminRolesController", {
                $scope: scope,
                $routeParams: routeParams,
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, FIXTURES.project)
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, FIXTURES.users)
            httpBackend.whenGET("#{APIURL}/permissions").respond(200, FIXTURES.permissions)
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, FIXTURES.roles)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section projects", ->
            expect(ctrl.section).to.be.equal("admin")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.equal("common.admin-panel")

        it "should change the location", ->
            sinon.spy(ctrl.location, "url")

            ctrl.goTo("roles")

            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/project/test/admin/roles")

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb).to.be.lengthOf(2)

        it "should be actived", ->
            expect(ctrl.isActive("roles")).to.be.true
