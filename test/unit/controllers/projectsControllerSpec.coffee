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

        it "should have the project list", ->
            expect(ctrl.scope.projects).to.be.lengthOf(2)
            expect(ctrl.scope.projects[0].slug).to.be.equal("test-proj-1")
            expect(ctrl.scope.projects[1].slug).to.be.equal("test-proj-2")

    describe "ShowProjectsController", ->
        httpBackend = null
        scope = null
        ctrl = null
        projectListIsEmpty = false

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            ctrl = $controller("ShowProjectsController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET(APIURL+"/projects").respond(() ->
                if projectListIsEmpty
                    return [200, []]
                return [200, [{name: "test proj 1", slug: "test-proj-1"},
                              {name: "test proj 2", slug: "test-proj-2"}]]
            )
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have the project list when call showProjects", ->
            projectListIsEmpty = false
            ctrl.scope.showProjects()
            httpBackend.flush()

            expect(ctrl.scope.myProjects).to.be.lengthOf(2)
            expect(ctrl.scope.myProjects[0].slug).to.be.equal("test-proj-1")
            expect(ctrl.scope.myProjects[1].slug).to.be.equal("test-proj-2")

        it "should have an empty project list when call showProjects and ther server have no projects", ->
            projectListIsEmpty = true
            ctrl.scope.showProjects()
            httpBackend.flush()

            expect(ctrl.scope.myProjects).to.be.lengthOf(0)
