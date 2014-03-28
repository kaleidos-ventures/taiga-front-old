describe 'resourceService', ->
    httpBackend = null

    beforeEach(module('taiga'))
    beforeEach(module('taiga.services.resource'))

    beforeEach inject ($httpBackend) ->
        httpBackend = $httpBackend
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
        httpBackend.whenGET(
            'http://localhost:8000/api/v1/resolver?issue=7&milestone=4&project=test&task=10&us=3'
        ).respond(200)
        httpBackend.whenGET(
            'http://localhost:8000/api/v1/resolver?issue=7&milestone=4&project=bad&task=10&us=3'
        ).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
        httpBackend.whenGET('http://localhost:8000/api/v1/site-members').respond(200)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/site-projects?template=kanban',
            {'test': 'test'}
        ).respond(200)
        httpBackend.whenPOST(
            'http://localhost:8000/api/v1/site-projects?template=kanban',
            {'test': 'bad'}
        ).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1?').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100?').respond(400)

        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1/stats').respond(200, { test: "test" })
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100/stats').respond(404)

        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1/issues_stats').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100/issues_stats').respond(404)

        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1/tags').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100/tags').respond(400)

    describe 'resource service', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

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

        it 'should allow to register a user', inject (resource, $gmAuth) ->
            $gmAuth.unsetUser(null)
            $gmAuth.setToken(null)
            expect($gmAuth.getToken()).to.be.null
            expect($gmAuth.getUser()).to.be.null
            httpBackend.expectPOST('http://localhost:8000/api/v1/auth/register', {"test": "data"})
            promise = resource.register({"test": "data"})
            promise.should.be.fullfilled
            httpBackend.flush()
            expect($gmAuth.getToken()).to.be.equal('test')
            expect($gmAuth.getUser().getAttrs()).to.be.deep.equal({"auth_token": "test"})

            httpBackend.expectPOST('http://localhost:8000/api/v1/auth/register', {"test": "bad-data"})
            promise = resource.register({"test": "bad-data"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to login with a username and password', inject (resource, $gmAuth) ->
            $gmAuth.unsetUser(null)
            $gmAuth.setToken(null)
            expect($gmAuth.getToken()).to.be.null
            expect($gmAuth.getUser()).to.be.null
            httpBackend.expectPOST('http://localhost:8000/api/v1/auth', {"username": "test", "password": "test"})
            promise = resource.login("test", "test")
            promise.should.be.fullfilled
            httpBackend.flush()
            expect($gmAuth.getToken()).to.be.equal('test')
            expect($gmAuth.getUser().getAttrs()).to.be.deep.equal({"auth_token": "test"})

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

        it 'should allow to resolve us/task/issue/milestone references or project slug', inject (resource) ->
            httpBackend.expectGET(
                'http://localhost:8000/api/v1/resolver?issue=7&milestone=4&project=test&task=10&us=3'
            )
            promise = resource.resolve({pslug: "test", usref: 3, taskref: 10, issueref: 7, mlref: 4})
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET(
                'http://localhost:8000/api/v1/resolver?issue=7&milestone=4&project=bad&task=10&us=3'
            )
            promise = resource.resolve({pslug: "bad", usref: 3, taskref: 10, issueref: 7, mlref: 4})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the site info', inject (resource) ->
            promise = resource.getSite()
            httpBackend.expectGET('http://localhost:8000/api/v1/sites')
            promise.should.fullfilled
            httpBackend.flush()

        it 'should allow to get the site members', inject (resource) ->
            promise = resource.getSiteMembers()
            httpBackend.expectGET('http://localhost:8000/api/v1/site-members')
            promise.should.fullfilled
            httpBackend.flush()

        it 'should allow to create a project', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/site-projects?template=kanban', {'test': 'test'})
            promise = resource.createProject({'test': 'test'}, 'kanban')
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/site-projects?template=kanban', {'test': 'bad'})
            promise = resource.createProject({'test': 'bad'}, 'kanban')
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the project list', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects')
            promise = resource.getProjects()
            promise.should.fullfilled
            httpBackend.flush()

        it 'should allow to get the list of permissions', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/permissions')
            promise = resource.getPermissions()
            httpBackend.flush()
            promise.should.be.fullfilled

        it 'should allow to get a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects/1?')
            promise = resource.getProject(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/projects/100?')
            promise = resource.getProject(100)
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

        it 'should allow to get a project issues stats', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects/1/issues_stats')
            promise = resource.getIssuesStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/projects/100/issues_stats')
            promise = resource.getIssuesStats(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a project tags', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects/1/tags')
            promise = resource.getProjectTags(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/projects/100/tags')
            promise = resource.getProjectTags(100)
            promise.should.be.rejected
            httpBackend.flush()
