describe 'authController', ->

    beforeEach(module('taiga'))
    beforeEach(module('taiga.controllers.auth'))

    describe 'LoginController', ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            scope = $rootScope.$new()
            ctrl = $controller('LoginController', {
                $scope: scope,
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

    describe 'RecoveryController', ->
        httpBackend = null
        scope = null
        ctrl = null
        clock = null

        beforeEach(inject(($rootScope, $controller, $httpBackend) ->
            clock = sinon.useFakeTimers()
            scope = $rootScope.$new()
            ctrl = $controller('RecoveryController', {
                $scope: scope,
                $rootScope: $rootScope,
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.whenPOST("http://localhost:8000/api/v1/users/password_recovery", {"username": "test"}).respond(200)
            httpBackend.whenPOST(
                "http://localhost:8000/api/v1/users/password_recovery",
                {"username": "bad"}
            ).respond(400, {"_error_message": "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()
            clock.restore()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('login')

        it 'should show an error message on recovery error', ->
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.errorMessage).to.be.equal('')
            expect(ctrl.scope.success).to.be.false
            ctrl.onError({"_error_message": "test-error"})
            expect(ctrl.scope.error).to.be.true
            expect(ctrl.scope.errorMessage).to.be.equal("test-error")
            expect(ctrl.scope.success).to.be.false

        it 'should show success message and redirect to login after a delay', ->
            sinon.spy(ctrl.location, "url")
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.success).to.be.false
            ctrl.onSuccess()
            clock.tick(2100)
            ctrl.location.url.getCall(0).calledWith('/login').should.be.ok
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.success).to.be.true

        it 'should send a recover request on submit', ->
            httpBackend.expectPOST("http://localhost:8000/api/v1/users/password_recovery", {"username": "test"})
            ctrl.scope.formData.email = "test"
            ctrl.submit()
            httpBackend.flush()
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.success).to.be.true

            httpBackend.expectPOST("http://localhost:8000/api/v1/users/password_recovery", {"username": "bad"})
            ctrl.scope.formData.email = "bad"
            ctrl.submit()
            httpBackend.flush()
            expect(ctrl.scope.error).to.be.true
            expect(ctrl.scope.errorMessage).to.be.equal('test')
            expect(ctrl.scope.success).to.be.false

    describe 'ChangePasswordController', ->
        httpBackend = null
        scope = null
        ctrl = null
        clock = null
        routeParams = null

        beforeEach(inject(($rootScope, $controller, $routeParams, $httpBackend) ->
            clock = sinon.useFakeTimers()
            scope = $rootScope.$new()
            routeParams = $routeParams
            ctrl = $controller('ChangePasswordController', {
                $scope: scope,
                $routeParams: routeParams,
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.whenPOST("http://localhost:8000/api/v1/users/change_password_from_recovery", {"token": "test-token", "password": "test-pass"}).respond(200)
            httpBackend.whenPOST("http://localhost:8000/api/v1/users/change_password_from_recovery", {"token": "bad-token", "password": "test-pass"}).respond(400, {"detail": "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()
            clock.restore()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('login')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to initialize without token in params', ->
            expect(ctrl.scope.error).to.be.false
            expect(ctrl.scope.success).to.be.false
            expect(ctrl.scope.formData).to.be.deep.equal({})
            expect(ctrl.scope.tokenInParams).to.be.false

        it 'should allow to initialize with token in params', inject ($rootScope, $routeParams, $controller) ->
            $routeParams.token = "test"
            scope = $rootScope.$new()
            newCtrl = $controller('ChangePasswordController', {
                $scope: scope,
                $routeParams: $routeParams,
            })
            expect(newCtrl.scope.tokenInParams).to.be.true

        it 'should allow to submit the change password request', ->
            sinon.spy(ctrl.location, "url")
            ctrl.scope.formData.token = "test-token"
            ctrl.scope.formData.password = "test-pass"
            httpBackend.expectPOST("http://localhost:8000/api/v1/users/change_password_from_recovery", {"token": "test-token", "password": "test-pass"})
            promise = ctrl.submit()
            httpBackend.flush()
            promise.should.be.fullfilled
            expect(ctrl.scope.success).to.be.true
            expect(ctrl.scope.error).to.be.false
            clock.tick(2100)
            ctrl.location.url.getCall(0).calledWith('/login').should.be.ok

            ctrl.scope.formData.token = "bad-token"
            ctrl.scope.formData.password = "test-pass"
            httpBackend.expectPOST("http://localhost:8000/api/v1/users/change_password_from_recovery", {"token": "bad-token", "password": "test-pass"})
            promise = ctrl.submit()
            httpBackend.flush()
            promise.should.be.rejected
            expect(ctrl.scope.error).to.be.true
            expect(ctrl.scope.success).to.be.false
            expect(ctrl.scope.formData).to.be.deep.equal({})
            expect(ctrl.scope.errorMessage).to.be.equal('test')

            ctrl.routeParams.token = "test-token"
            ctrl.scope.formData.password = "test-pass"
            httpBackend.expectPOST("http://localhost:8000/api/v1/users/change_password_from_recovery", {"token": "test-token", "password": "test-pass"})
            promise = ctrl.submit()
            httpBackend.flush()
            promise.should.be.fullfilled
            expect(ctrl.scope.success).to.be.true
            expect(ctrl.scope.error).to.be.false
            clock.tick(2100)
            ctrl.location.url.getCall(0).calledWith('/login').should.be.ok
