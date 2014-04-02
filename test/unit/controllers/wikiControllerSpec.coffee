describe 'wikiController', ->

    beforeEach(module('taiga'))
    beforeEach(module('taiga.controllers.site'))

    describe 'WikiHelpController', ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $routeParams) ->
            scope = $rootScope.$new()
            $routeParams.pslug = "test"
            ctrl = $controller('WikiHelpController', {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('wiki')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should set the breadcrumb', ->
            expect(ctrl.rootScope.pageBreadcrumb.length).to.be.equal(1)
