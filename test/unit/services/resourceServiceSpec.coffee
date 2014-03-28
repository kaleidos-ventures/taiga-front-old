describe 'resourceService', ->
    httpBackend = null

    beforeEach(module('taiga'))
    beforeEach(module('taiga.services.resource'))

    beforeEach inject ($httpBackend) ->
        httpBackend = $httpBackend
        httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?project=1').respond(200, [{order: 3}, {order: 1}])
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?project=100').respond(404)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?milestone=null&project=1').respond(200, [
            {project: 1, order: 3, milestone: null}
            {project: 1, order: 1, milestone: null}
            {project: 1, order: 7, milestone: 2}
        ])
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?milestone=null&project=100').respond(404)
        httpBackend.whenGET('http://localhost:8000/api/v1/permissions').respond(200, [
            {codename: 'view_us'}
            {codename: 'edit_us'}
            {codename: 'view_task'}
            {codename: 'edit_task'}
        ])
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1/stats').respond(200, { test: "test" })
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100/stats').respond(404)

        httpBackend.whenPOST('http://localhost:8000/api/v1/auth/register', {"test": "data"}).respond(200, {'auth_token': 'test'})
        httpBackend.whenPOST('http://localhost:8000/api/v1/auth/register', {"test": "bad-data"}).respond(400)

        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/auth',
            {"username": "test", "password": "test"}
        ).respond(200, {'auth_token': 'test'})
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/auth',
            {"username": "bad", "password": "bad"}
        ).respond(400)

        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/password_recovery',
            {"username": "test"}
        ).respond(200, {'auth_token': 'test'})
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/password_recovery',
            {"username": "bad"}
        ).respond(400)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/change_password_from_recovery',
            {"password": "test", "token": "test"}
        ).respond(200)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/change_password_from_recovery',
            {"password": "bad", "token": "bad"}
        ).respond(400)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/change_password',
            {"password": "test"}
        ).respond(200)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/users/change_password',
            {"password": "bad"}
        ).respond(400)

    describe 'resource service', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should allow to get the site info', inject (resource) ->
            promise = resource.getSite()
            httpBackend.expectGET('http://localhost:8000/api/v1/sites')
            promise.should.fullfilled
            httpBackend.flush()

        it 'should allow to get the userstories of a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?project=1')
            promise = resource.getUserStories(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?project=100')
            promise = resource.getUserStories(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get unassigned userstories of a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?milestone=null&project=1')
            promise = resource.getUnassignedUserStories(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?milestone=null&project=100')
            promise = resource.getUnassignedUserStories(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a project stats', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects/1/stats')
            promise = resource.getProjectStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/projects/100/stats')
            promise = resource.getProjectStats(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the list of permissions', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/permissions')
            promise = resource.getPermissions()
            httpBackend.flush()
            promise.should.be.fullfilled

        it 'should allow to register a user', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/auth/register', {"test": "data"})
            promise = resource.register({"test": "data"})
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/auth/register', {"test": "bad-data"})
            promise = resource.register({"test": "bad-data"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to login with a username and password', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/auth', {"username": "test", "password": "test"})
            promise = resource.login("test", "test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/auth', {"username": "bad", "password": "bad"})
            promise = resource.login("bad", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to recover password with your email', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/users/password_recovery', {"username": "test"})
            promise = resource.recovery("test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/users/password_recovery', {"username": "bad"})
            promise = resource.recovery("bad")
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to change password from a recovery token', inject (resource) ->
            httpBackend.expectPOST(
                'http://localhost:8000/api/v1/users/change_password_from_recovery',
                {"password": "test", "token": "test"}
            )
            promise = resource.changePasswordFromRecovery("test", "test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                'http://localhost:8000/api/v1/users/change_password_from_recovery',
                {"password": "bad", "token": "bad"}
            )
            promise = resource.changePasswordFromRecovery("bad", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to change password for the current user', inject (resource) ->
            httpBackend.expectPOST(
                'http://localhost:8000/api/v1/users/change_password',
                {"password": "test"}
            )
            promise = resource.changePasswordForCurrentUser("test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                'http://localhost:8000/api/v1/users/change_password',
                {"password": "bad"}
            )
            promise = resource.changePasswordForCurrentUser("bad")
            promise.should.be.rejected
            httpBackend.flush()
