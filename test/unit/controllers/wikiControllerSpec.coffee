describe "wikiController", ->

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.site"))

    describe "WikiHelpController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $routeParams) ->
            scope = $rootScope.$new()
            ctrl = $controller("WikiHelpController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("http://localhost:8000/api/v1/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section login", ->
            expect(ctrl.section).to.be.equal("wiki")

        it "should have a title", ->
            expect(ctrl.getTitle).to.be.ok

        it "should set the breadcrumb", ->
            expect(ctrl.rootScope.pageBreadcrumb.length).to.be.equal(1)

    describe "WikiController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $routeParams, $q) ->
            scope = $rootScope.$new()
            $routeParams.slug = "test"
            $routeParams.pslug = "ptest"
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("WikiController", {
                $scope: scope
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("http://localhost:8000/api/v1/sites").respond(200, {test: "test"})
            httpBackend.whenGET("http://localhost:8000/api/v1/resolver?project=ptest").respond(200, {project: 1})
            httpBackend.whenGET("http://localhost:8000/api/v1/projects/1?").respond(200, {id: 1, ref: "2", points: []})
            httpBackend.whenGET("http://localhost:8000/api/v1/wiki?project=1&slug=test").respond(200, {slug: "test", content: "test-content"})
            httpBackend.whenGET("http://localhost:8000/api/v1/wiki-attachments?project=1").respond(200, [])
            httpBackend.whenGET("http://localhost:8000/api/v1/users?project=1").respond(200, [])
            httpBackend.whenGET("http://localhost:8000/api/v1/roles?project=1").respond(200, [])
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section login", ->
            expect(ctrl.section).to.be.equal("wiki")

        it "should have a title", ->
            expect(ctrl.getTitle()).to.be.ok

        it "should display the form if the page does not exists", ->
            ctrl.scope.formOpened = false
            httpBackend.expectGET("http://localhost:8000/api/v1/wiki?project=1&slug=test").respond(404)
            ctrl.initialize()
            httpBackend.flush()
            expect(ctrl.scope.formOpened).to.be.true

        it "should allow to save a new attachment", inject ($q) ->
            ctrl.rs.uploadWikiPageAttachment = (projectId, pageId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            ctrl.scope.projectId = 1
            ctrl.scope.page = {id: "test"}
            ctrl.scope.newAttachments = []
            result = ctrl.saveNewAttachments()
            expect(result).to.be.null

            httpBackend.expectGET("http://localhost:8000/api/v1/wiki-attachments?object_id=test&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.page = {id: "test"}
            ctrl.scope.newAttachments = ["good", "good", "good"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it "should allow to save a new attachment (taking care on errors)", inject ($q) ->
            sinon.spy(ctrl.gmFlash, "error")

            ctrl.rs.uploadWikiPageAttachment = (projectId, pageId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            httpBackend.expectGET("http://localhost:8000/api/v1/wiki-attachments?object_id=test&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.page = {id: "test"}
            ctrl.scope.newAttachments = ["bad", "bad", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledOnce

            httpBackend.expectGET("http://localhost:8000/api/v1/wiki-attachments?object_id=test&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.page = {id: "test"}
            ctrl.scope.newAttachments = ["good", "good", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledTwice

        it "should allow to open the edit form and copy the current page content", ->
            ctrl.scope.formOpened = false
            ctrl.scope.content = ""
            ctrl.scope.page = {content: "test"}
            ctrl.openEditForm()
            expect(ctrl.scope.formOpened).to.be.true
            expect(ctrl.scope.content).to.be.equal("test")

        it "should allow to discard the current changes", ->
            ctrl.scope.newAttachments = ["test"]
            ctrl.scope.formOpened = true
            ctrl.scope.content = "test-content"
            ctrl.scope.page = {content: "test"}

            ctrl.discardCurrentChanges()

            expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.content).to.be.equal("test")
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

            ctrl.scope.newAttachments = ["test"]
            ctrl.scope.formOpened = true
            ctrl.scope.content = "test-content"
            ctrl.scope.page = undefined

            ctrl.discardCurrentChanges()

            expect(ctrl.scope.formOpened).to.be.true
            expect(ctrl.scope.content).to.be.equal("")
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it "should allow to save the page", ->
            ctrl.saveNewAttachments = ->
            ctrl.scope.projectId = 1
            ctrl.rootScope.slug = "test"
            ctrl.scope.content = "test-content"
            ctrl.scope.page = undefined

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/wiki",
                {"content":"test-content", "slug":"test", "project":1}
            ).respond(200, {"test": "test", "content": "test-content"})
            promise = ctrl._savePage()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.page.getAttrs()).to.be.deep.equal({"test": "test", "content": "test-content"})
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.content).to.be.equal("test-content")

        it "should manage save page errors", ->
            ctrl.saveNewAttachments = ->
            ctrl.scope.projectId = 1
            ctrl.rootScope.slug = "test"
            ctrl.scope.content = "test-content"
            ctrl.scope.page = undefined
            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/wiki",
                {"content":"test-content", "slug":"test", "project":1}
            ).respond(400)
            promise = ctrl._savePage()
            httpBackend.flush()
            promise.should.have.been.rejected

        it "should allow to update the page (savePage)", inject ($model) ->
            ctrl.saveNewAttachments = ->
            ctrl.scope.projectId = 1
            ctrl.rootScope.slug = "test"
            ctrl.scope.content = "test-content"
            ctrl.scope.page = $model.make_model('wiki', {"id": "test", "content": "test"})
            httpBackend.expectPATCH(
                "http://localhost:8000/api/v1/wiki/test",
                {"content":"test-content"}
            ).respond(200, {"id": "test", "content": "test-content"})
            promise = ctrl._savePage()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.page.getAttrs()).to.be.deep.equal({"id": "test", "content": "test-content"})
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.content).to.be.equal("test-content")

        it 'should allow to delete a wiki page', inject ($model) ->
            ctrl.scope.page = $model.make_model('wiki', {"id": "test", "content": "test"})
            httpBackend.expectDELETE("http://localhost:8000/api/v1/wiki/test").respond(200)
            promise = ctrl.deletePage()
            promise.should.be.fulfilled
            httpBackend.flush()
            expect(ctrl.scope.page).to.be.undefined
            expect(ctrl.scope.content).to.be.equal("")
            expect(ctrl.scope.attachments).to.be.deep.equal([])
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])
            expect(ctrl.scope.formOpened).to.be.true

        it 'should allow to delete a wiki page attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('wiki/attachments', {"id": "test", "content": "test"})]
            httpBackend.expectDELETE("http://localhost:8000/api/v1/wiki-attachments/test").respond(200)
            promise = ctrl.deleteAttachment(ctrl.scope.attachments[0])
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.attachments).to.be.deep.equal([])

        it 'should allow to delete a not uploaded attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('wiki/attachments', {"id": "test", "content": "test"})]
            ctrl.deleteNewAttachment(ctrl.scope.attachments[0])
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

    describe "WikiHistoricalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $routeParams) ->
            scope = $rootScope.$new()
            $routeParams.slug = "test"
            $routeParams.pslug = "ptest"
            ctrl = $controller("WikiHistoricalController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("http://localhost:8000/api/v1/sites").respond(200, {test: "test"})
            httpBackend.whenGET("http://localhost:8000/api/v1/resolver?project=ptest").respond(200, {project: 1})
            httpBackend.whenGET("http://localhost:8000/api/v1/projects/1?").respond(200, {id: 1, ref: "2", points: []})
            httpBackend.whenGET("http://localhost:8000/api/v1/wiki?project=1&slug=test").respond(200, [{id: "test", content: "test-content"}])
            httpBackend.whenGET("http://localhost:8000/api/v1/wiki-attachments?object_id=test&project=1").respond(200, [])
            httpBackend.whenGET("http://localhost:8000/api/v1/wiki/test/historical?page=1").respond(200, [{"test1": "test1"}])
            httpBackend.whenGET("http://localhost:8000/api/v1/users?project=1").respond(200, [])
            httpBackend.whenGET("http://localhost:8000/api/v1/roles?project=1").respond(200, [])
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section login", ->
            expect(ctrl.section).to.be.equal("wiki")

        it "should have a title", ->
            expect(ctrl.getTitle).to.be.ok

        it "should reload the page after a restore", inject ($model) ->
            ctrl.scope.content = "other-content"
            ctrl.scope.page = $model.make_model('wiki', {"id": "other", "content": "other"})
            httpBackend.expectGET("http://localhost:8000/api/v1/wiki?project=1&slug=test").respond(200, [{id: "test", content: "test-content"}])
            httpBackend.expectGET("http://localhost:8000/api/v1/wiki/test/historical?page=1").respond(200, [])
            ctrl.scope.$emit("wiki:restored")
            httpBackend.flush()
            expect(ctrl.scope.page.getAttrs()).to.be.deep.equal({id: "test", content: "test-content"})
            expect(ctrl.scope.content).to.be.equal("test-content")

        it "should allow to load more historical", inject ($model) ->
            httpBackend.expectGET(
                "http://localhost:8000/api/v1/wiki/test/historical?page=1"
            ).respond(200, [{"test1": "test1"}, {"test2": "test2"}])
            promise = ctrl.loadHistorical()
            httpBackend.flush()
            promise.then ->
                expect(ctrl.scope.historical.models.length).to.be.equal(1)

            httpBackend.expectGET(
                "http://localhost:8000/api/v1/wiki/test/historical?page=2"
            ).respond(200, [{"test3": "test3"}])
            promise = ctrl.loadMoreHistorical()
            httpBackend.flush()
            promise.then ->
                expect(ctrl.scope.historical.models.length).to.be.equal(2)

        it "should load the first page historical on loadMorehistorical when no historical", inject ($model) ->
            ctrl.scope.historical = null
            httpBackend.expectGET(
                "http://localhost:8000/api/v1/wiki/test/historical?page=1"
            ).respond(200, [{"test1": "test1"}, {"test2": "test2"}])
            promise = ctrl.loadMoreHistorical()
            httpBackend.flush()

    describe "WikiHistoricalItemController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $routeParams, $q) ->
            scope = $rootScope.$new()
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("WikiHistoricalItemController", {
                $scope: scope
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("http://localhost:8000/api/v1/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to show changes", ->
            expect(ctrl.scope.showChanges).to.be.false
            ctrl.toggleShowChanges()
            expect(ctrl.scope.showChanges).to.be.true

        it "should allow to show historical item content", ->
            ctrl.showContent = false
            expect(ctrl.scope.showPreviousDiff).to.be.false
            expect(ctrl.scope.showCurrentDiff).to.be.false
            ctrl.activeShowContent()
            expect(ctrl.scope.showContent).to.be.true
            expect(ctrl.scope.showPreviousDiff).to.be.false
            expect(ctrl.scope.showCurrentDiff).to.be.false

        it "should allow to show historical differences with previous version", ->
            expect(ctrl.scope.showContent).to.be.true
            expect(ctrl.scope.showPreviousDiff).to.be.false
            expect(ctrl.scope.showCurrentDiff).to.be.false
            ctrl.activeShowPreviousDiff()
            expect(ctrl.scope.showContent).to.be.false
            expect(ctrl.scope.showPreviousDiff).to.be.true
            expect(ctrl.scope.showCurrentDiff).to.be.false

        it "should allow to show historical differences with current version", ->
            expect(ctrl.scope.showContent).to.be.true
            expect(ctrl.scope.showPreviousDiff).to.be.false
            expect(ctrl.scope.showCurrentDiff).to.be.false
            ctrl.activeShowCurrentDiff()
            expect(ctrl.scope.showContent).to.be.false
            expect(ctrl.scope.showPreviousDiff).to.be.false
            expect(ctrl.scope.showCurrentDiff).to.be.true

        it "should allow to restoreWikiPage", ->
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl.gmFlash, "error")
            sinon.spy(ctrl.scope, "$emit")

            hitem = {created_date: "2014-01-01", object_id: "test", id: 1}
            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/wiki/test/restore?version=1"
            ).respond(200)
            ctrl.restoreWikiPage(hitem)
            httpBackend.flush()
            ctrl.scope.$emit.should.have.been.calledWith("wiki:restored")
            ctrl.gmFlash.info.should.have.been.calledOnce

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/wiki/test/restore?version=1"
            ).respond(400)
            ctrl.restoreWikiPage(hitem)
            httpBackend.flush()
            ctrl.gmFlash.error.should.have.been.calledOnce
