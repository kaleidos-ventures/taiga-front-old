describe 'dataService', ->
    rootScope = null
    httpBackend = null

    beforeEach(module('taiga'))
    beforeEach(module('taiga.services.data'))

    beforeEach inject ($httpBackend) ->
        httpBackend = $httpBackend
        httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?project=1').respond(200, [{order: 3}, {order: 1}])

    describe '$data', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should allow to load the site info in the scope.site variable', inject ($data, $rootScope) ->
            scope = $rootScope.$new()
            httpBackend.expectGET('http://localhost:8000/api/v1/sites')
            $data.loadSiteInfo(scope)
            httpBackend.flush()
            expect(scope.site).to.be.deep.equal({headers: {}, data: {test: "test"}})
            scope.site = {}

        it 'should allow to load the userstories of the current project', inject ($data, $rootScope, $model) ->
            scope = $rootScope.$new()
            $rootScope.projectId = 1
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?project=1')
            $data.loadUserStories(scope)
            httpBackend.flush()
            expect(_.map(scope.userstories, (us) -> us.getAttrs())).to.be.deep.equal([{order: 1}, {order: 3}])
