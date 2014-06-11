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
            httpBackend.whenPOST("http://localhost:8000/api/v1/auth", {"username": "test", "password": "test", "type": "normal"}).respond(200, {"auth_token": "test"})
            httpBackend.whenPOST("http://localhost:8000/api/v1/auth", {"username": "bad", "password": "bad", "type": "normal"}).respond(400, {'detail': 'test'})
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
            httpBackend.expectPOST("http://localhost:8000/api/v1/auth", {"username": "test", "password": "test", "type": "normal"})
            ctrl.scope.form.username = "test"
            ctrl.scope.form.password = "test"
            ctrl.submit()
            httpBackend.flush()
            expect(ctrl.scope.error).to.be.false

            httpBackend.expectPOST("http://localhost:8000/api/v1/auth", {"username": "bad", "password": "bad", "type": "normal"})
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
            promise.should.be.fulfilled
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
            promise.should.be.fulfilled
            expect(ctrl.scope.success).to.be.true
            expect(ctrl.scope.error).to.be.false
            clock.tick(2100)
            ctrl.location.url.getCall(0).calledWith('/login').should.be.ok

    describe 'ProfileController', ->
        httpBackend = null
        scope = null
        ctrl = null
        clock = null
        routeParams = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            clock = sinon.useFakeTimers()
            scope = $rootScope.$new()
            gmFlashMock = {
                info: (text) ->
            }
            gmAuthMock = {
                setUser: (user) ->
            }
            resourceMock = {
                changePasswordForCurrentUser: (password) ->
                    defered = $q.defer()
                    if password == "test"
                        defered.resolve("test")
                    else if password == "bad"
                        defered.reject("test")
                    return defered.promise
            }
            ctrl = $controller('ProfileController', {
                $scope: scope
                $gmFlash: gmFlashMock
                $gmAuth: gmAuthMock
                resource: resourceMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()
            clock.restore()

        it 'should have section profile', ->
            expect(ctrl.section).to.be.equal('profile')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to submit the profile info', inject ($model) ->
            sinon.spy(ctrl.gmAuth, "setUser")
            sinon.spy(ctrl.gmFlash, "info")

            httpBackend.expectPATCH("http://localhost:8000/api/v1/users/1", {"test": "test"}).respond(200)
            form = $model.make_model("users", {id: 1, test: ""})
            form.test = "test"
            promise = ctrl.submitProfile(form)
            httpBackend.flush()
            promise.should.be.fulfilled

            ctrl.gmAuth.setUser.should.have.been.calledOnce
            ctrl.gmFlash.info.should.have.been.calledOnce

            httpBackend.expectPATCH("http://localhost:8000/api/v1/users/1", {"test": "bad"}).respond(400, {'detail': 'test'})
            form = $model.make_model("users", {id: 1, test: ""})
            form.test = "bad"
            promise = ctrl.submitProfile(form)
            httpBackend.flush()
            promise.should.become({'detail': 'test'})
            expect(ctrl.scope.checksleyErrors).to.be.deep.equal({'detail': 'test'})

            # No extra calls
            ctrl.gmAuth.setUser.should.have.been.calledOnce
            ctrl.gmFlash.info.should.have.been.calledOnce

        it 'should allow to submit the password info', ->
            sinon.spy(ctrl.gmFlash, "info")

            ctrl.scope.formData.password = "test"
            promise = ctrl.submitPassword()
            promise.should.be.fulfilled.then ->
                ctrl.gmFlash.info.should.to.be.calledOnce

            ctrl.scope.formData.password = "bad"
            promise = ctrl.submitPassword()
            promise.should.be.rejected

    describe 'PublicRegisterController', ->
        httpBackend = null
        scope = null
        ctrl = null
        clock = null
        routeParams = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            clock = sinon.useFakeTimers()
            scope = $rootScope.$new()
            resourceMock = {
                register: (form) ->
                    defered = $q.defer()
                    if form.test == "test"
                        defered.resolve("test")
                    else if form.test == "bad"
                        defered.reject({_error_message: "test"})
                    return defered.promise
            }
            ctrl = $controller('PublicRegisterController', {
                $scope: scope
                resource: resourceMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()
            clock.restore()

        it 'should have section profile', ->
            expect(ctrl.section).to.be.equal('login')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to submit the register form', inject ($model) ->
            sinon.spy(ctrl.location, "url")

            ctrl.scope.form = {"test": "test"}
            promise = ctrl.submit()
            promise.should.be.fulfilled.then ->
                ctrl.location.url.should.have.been.calledOnce
                ctrl.location.url.should.have.been.calledWith("/")

            ctrl.scope.form = {"test": "bad"}
            promise = ctrl.submit()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({"_error_message": "test"})
                expect(ctrl.scope.error).to.be.true
                expect(ctrl.scope.errorMessage).to.be.equal("test")

        it 'should watch the site.data.public_register variable ', ->
            sinon.spy(ctrl.location, "url")

            ctrl.scope.$apply ->
                ctrl.scope.site.data.public_register = true
            ctrl.location.url.should.not.have.been.called

            ctrl.scope.$apply ->
                ctrl.scope.site.data.public_register = false
            ctrl.location.url.should.have.been.calledOnce
            ctrl.location.url.should.have.been.calledWith("/login")

    describe 'InvitationRegisterController', ->
        httpBackend = null
        scope = null
        ctrl = null
        clock = null
        routeParams = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            clock = sinon.useFakeTimers()
            scope = $rootScope.$new()
            resourceMock = {
                register: (form) ->
                    defered = $q.defer()
                    if form.test == "test"
                        defered.resolve("test")
                    else if form.test == "bad"
                        defered.reject({_error_message: "test"})
                    return defered.promise
            }
            ctrl = $controller('InvitationRegisterController', {
                $scope: scope
                resource: resourceMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()
            clock.restore()

        it 'should have section profile', ->
            expect(ctrl.section).to.be.equal('login')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to submit the register form', ->
            sinon.spy(ctrl.location, "url")

            ctrl.scope.form = {"test": "test"}
            promise = ctrl.submit()
            promise.should.be.fulfilled.then ->
                ctrl.location.url.should.have.been.calledOnce
                ctrl.location.url.should.have.been.calledWith("/")

            ctrl.scope.form = {"test": "bad"}
            promise = ctrl.submit()
            promise.should.be.rejected
