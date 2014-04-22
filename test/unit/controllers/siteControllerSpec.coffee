describe 'siteController', ->

    beforeEach(module('taiga'))
    beforeEach(module('taiga.controllers.site'))

    describe 'SiteAdminController', ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            scope = $rootScope.$new()
            confirmMock = {
                resolve: true
                confirm: (text) ->
                    defered = $q.defer()
                    if @resolve
                        defered.resolve("test")
                    else
                        defered.reject("test")
                    return defered.promise
            }
            gmFlashMock = {
                info: (text) ->
                error: (text) ->
            }
            ctrl = $controller('SiteAdminController', {
                $scope: scope
                $gmFlash: gmFlashMock
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.whenGET('http://localhost:8000/api/v1/site-members').respond(200, {test: "test"})
            httpBackend.whenGET('http://localhost:8000/api/v1/project-templates').respond(200, [{test: "test"}])
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('admin')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to activate a tab', ->
            expect(ctrl.scope.activeTab).to.be.equal("data")
            ctrl.setActive("test")
            expect(ctrl.scope.activeTab).to.be.equal("test")

        it 'should allow to check if a tab is active', ->
            ctrl.setActive("test")
            expect(ctrl.isActive("test")).to.be.true
            ctrl.setActive("bad")
            expect(ctrl.isActive("test")).to.be.false

        it 'should not modify the newProjectTemplate on loadSite if newProjectTemplate is modified', ->
            httpBackend.expectGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.expectGET('http://localhost:8000/api/v1/project-templates').respond(200, [{test: "test"}])
            ctrl.scope.newProjectTemplate = "test"
            promise = ctrl.loadSite()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.newProjectTemplate).to.be.equal("test")

        it 'should set member role', inject ($model) ->
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl.gmFlash, "error")

            mbr = $model.make_model('site-members', {id: 1, 'is_owner': true, 'is_staff': true})
            expect(() -> ctrl.setMemberAs(mbr, "test")).to.throw('invalid role')

            httpBackend.expectPATCH("http://localhost:8000/api/v1/site-members/1", {'is_owner': false, 'is_staff': false}).respond(200, '')
            promise = ctrl.setMemberAs(mbr, "normal")
            httpBackend.flush()
            promise.should.have.been.fulfilled.then ->
                ctrl.gmFlash.info.should.have.been.calledOnce
                ctrl.gmFlash.info.reset()

            httpBackend.expectPATCH("http://localhost:8000/api/v1/site-members/1", {'is_staff': true}).respond(200)
            promise = ctrl.setMemberAs(mbr, "staff")
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                ctrl.gmFlash.info.should.have.been.calledOnce
                ctrl.gmFlash.info.reset()

            httpBackend.expectPATCH("http://localhost:8000/api/v1/site-members/1", {'is_owner': true}).respond(200)
            promise = ctrl.setMemberAs(mbr, "owner")
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                ctrl.gmFlash.info.should.have.been.calledOnce
                ctrl.gmFlash.info.reset()

            httpBackend.expectPATCH("http://localhost:8000/api/v1/site-members/1", {'is_owner': false, 'is_staff': false}).respond(400)
            promise = ctrl.setMemberAs(mbr, "normal")
            httpBackend.flush()
            promise.should.have.been.rejected
            promise.then ->
                ctrl.gmFlash.error.should.have.been.calledOnce
                ctrl.gmFlash.error.reset()

        it 'should allow to submit site information', ->
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl.rootScope, "$broadcast")

            httpBackend.expectPOST("http://localhost:8000/api/v1/sites").respond(200, {"test": "test"})
            promise = ctrl.submit()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                ctrl.gmFlash.info.should.have.been.calledOnce
                expect(ctrl.scope.site.data.getAttrs()).to.be.deep.equal({"test": "test"})
                ctrl.rootScope.$broadcast.should.have.been.calledWith('i18n:change')

            httpBackend.expectPOST("http://localhost:8000/api/v1/sites").respond(400, {"test": "test"})
            promise = ctrl.submit()
            httpBackend.flush()
            promise.should.have.been.rejected

        it 'should allow to delete a project', ->
            ctrl.confirm.resolve = true
            httpBackend.expectDELETE("http://localhost:8000/api/v1/site-projects/1").respond(200)
            promise = ctrl.deleteProject({id: 1})
            httpBackend.flush()
            promise.should.be.fulfilled

        it 'should allow to open a new project form', ->
            ctrl.scope.addProjectFormOpened = false
            ctrl.scope.newProjectName = "test"
            ctrl.scope.newProjectDescription = "test"
            ctrl.scope.newProjectSprints = "test"
            ctrl.scope.newProjectPoints = "test"

            ctrl.openNewProjectForm()

            expect(ctrl.scope.addProjectFormOpened).to.be.true
            expect(ctrl.scope.newProjectName).to.be.equal("")
            expect(ctrl.scope.newProjectDescription).to.be.equal("")
            expect(ctrl.scope.newProjectSprints).to.be.equal("")
            expect(ctrl.scope.newProjectPoints).to.be.equal("")

        it 'should allow to close a new project form', ->
            ctrl.closeNewProjectForm()
            expect(ctrl.scope.addProjectFormOpened).to.be.false

        it 'should allow to submit a new project form', ->
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.newProjectName = "test"
            ctrl.scope.newProjectDescription = "test-desc"
            ctrl.scope.newProjectPoints = "test-points"
            ctrl.scope.newProjectSprints = "test-sprints"

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/site-projects?",
                {
                    "name": "test"
                    "description": "test-desc"
                    "total_story_points": "test-points"
                    "total_milestones": "test-sprints"
                }
            ).respond(200)
            promise = ctrl.submitProject()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.addProjectFormOpened).to.be.false
                ctrl.gmFlash.info.should.have.been.calledOnce
                expect(ctrl.scope.addProjectFormOpened).to.be.false

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/site-projects?",
                {
                    "name": "test"
                    "description": "test-desc"
                    "total_story_points": "test-points"
                    "total_milestones": "test-sprints"
                }
            ).respond(400)
            promise = ctrl.submitProject()
            httpBackend.flush()
            promise.should.have.been.rejected
