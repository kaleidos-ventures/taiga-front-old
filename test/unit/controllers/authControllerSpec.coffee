describe 'authController', ->

    beforeEach(module('taiga'))
    beforeEach(module('taiga.controllers.auth'))

    describe 'LoginController', ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $location, $controller, $routeParams, resource, $gmAuth, $i18next, $favico, $httpBackend) ->
            scope = $rootScope.$new()
            ctrl = $controller('LoginController', {
                $scope: scope,
                $rootScope: $rootScope,
                $location: $location,
                $routeParams: $routeParams,
                resource: resource,
                $gmAuth: $gmAuth,
                $i18next: $i18next,
                $favico: $favico
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.whenPOST("http://localhost:8000/api/v1/auth", {"username": "test", "password": "test"}).respond(200, {"auth_token": "test"})
            httpBackend.whenPOST("http://localhost:8000/api/v1/auth", {"username": "bad", "password": "bad"}).respond(400, {'detail': 'test'})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('login')

        it 'should show an error message on login error', ->
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.errorMessage).to.be.equal('')
            ctrl.onError({"detail": "test-error"})
            expect(ctrl.scope.error).to.be.true
            expect(ctrl.scope.errorMessage).to.be.equal("test-error")

        it 'should redirect you on login success', ->
            sinon.spy(ctrl.location, "url")
            ctrl.onSuccess()
            ctrl.location.url.getCall(0).calledWith('/').should.be.ok
            ctrl.routeParams.next = "/login"

            ctrl.onSuccess()
            ctrl.location.url.getCall(1).calledWith('/').should.be.ok
            ctrl.routeParams.next = "/test"

            ctrl.onSuccess()
            ctrl.location.url.getCall(2).calledWith('/test').should.be.ok

        it 'should send a login request on submit', ->
            httpBackend.expectPOST("http://localhost:8000/api/v1/auth", {"username": "test", "password": "test"})
            ctrl.scope.form.username = "test"
            ctrl.scope.form.password = "test"
            ctrl.submit()
            httpBackend.flush()
            expect(ctrl.scope.error).to.be.false

            httpBackend.expectPOST("http://localhost:8000/api/v1/auth", {"username": "bad", "password": "bad"})
            ctrl.scope.form.username = "bad"
            ctrl.scope.form.password = "bad"
            ctrl.submit()
            httpBackend.flush()
            expect(ctrl.scope.error).to.be.true
            expect(ctrl.scope.errorMessage).to.be.equal('test')
