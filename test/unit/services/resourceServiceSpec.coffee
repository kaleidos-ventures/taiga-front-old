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
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/1/issue_filters_data').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/projects/100/issue_filters_data').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/memberships?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/memberships?', {"test": "bad"}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/roles?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/roles?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/roles?', {"test": "test", "project": 1}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/roles?', {"test": "bad", "project": 1}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones?project=1').respond(200, [{"user_stories": [{"test": "test"}]}])
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones?project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones/1?project=1').respond(200, {"user_stories": [{"test": "test"}]})
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones/100?project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/resolver').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones/1/stats').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/milestones/100/stats').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?milestone=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories?milestone=100&project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories/1?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories/100?project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories/1/historical').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories/100/historical').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstories/1/historical?filter=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks?milestone=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks?milestone=100&project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues?project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues?filters=test&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues/1?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues/100?project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues/1/historical').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues/100/historical').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issues/1/historical?filter=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks/1?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks/100?project=1').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks/1/historical').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks/100/historical').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/tasks/1/historical?filter=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/search?get_all=false&project=1&text=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/search?get_all=false&project=1&text=bad').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/users?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/users?project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/users').respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issues', {"test": "test", "project": 1}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issues', {"test": "bad", "project": 1}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories/bulk_create', {"test": "test", "projectId": 1}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories/bulk_create', {"test": "bad", "projectId": 1}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "test", "projectId": 1, "usId": 2}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "bad", "projectId": 1, "usId": 2}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories/bulk_update_order', {"projectId": 1, "bulkStories": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstories/bulk_update_order', {"projectId": 100, "bulkStories": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenPATCH('http://localhost:8000/api/v1/userstories/1', {"milestone": 2}).respond(200)
        httpBackend.whenPATCH('http://localhost:8000/api/v1/userstories/100', {"milestone": 1}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/milestones', {"project": 1, "test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/milestones', {"project": 100, "test": "test"}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki?project=1&slug=test').respond(200, "wiki")
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki?project=1&slug=bad').respond(400, "wiki")
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki?project=1&slug=empty').respond(200, [])
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki/test/historical').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki/test/historical?filters=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki/bad/historical?filters=test').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/tasks?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/tasks?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/wiki/test/restore?version=1').respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/wiki/bad/restore?version=1').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/wiki', {"content": "test", "slug": "test-slug", "project": 1}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/wiki', {"content": "bad", "slug": "test-slug", "project": 1}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-attachments?object_id=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-attachments?object_id=1&project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/task-attachments?object_id=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/task-attachments?object_id=1&project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstory-attachments?object_id=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstory-attachments?object_id=1&project=100').respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki-attachments?object_id=1&project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/wiki-attachments?object_id=1&project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-attachments', {"project": 1, "object_id": 1, "data": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-attachments', {"project": 1, "object_id": 1, "data": "bad"}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstory-statuses?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstory-statuses?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/userstory-statuses?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstory-statuses?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstory-statuses?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstory-statuses/bulk_update_order', {"project": 1, "bulk_userstory_statuses": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/userstory-statuses/bulk_update_order', {"project": 100, "bulk_userstory_statuses": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/points?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/points?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/points?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/points?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/points?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/points/bulk_update_order', {"project": 1, "bulk_points": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/points/bulk_update_order', {"project": 100, "bulk_points": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/task-statuses?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/task-statuses?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/task-statuses?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/task-statuses?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/task-statuses?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/task-statuses/bulk_update_order', {"project": 1, "bulk_task_statuses": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/task-statuses/bulk_update_order', {"project": 100, "bulk_task_statuses": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-statuses?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-statuses?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-statuses?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-statuses?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-statuses?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-statuses/bulk_update_order', {"project": 1, "bulk_issue_statuses": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-statuses/bulk_update_order', {"project": 100, "bulk_issue_statuses": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-types?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-types?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/issue-types?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-types?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-types?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-types/bulk_update_order', {"project": 1, "bulk_issue_types": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/issue-types/bulk_update_order', {"project": 100, "bulk_issue_types": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/priorities?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/priorities?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/priorities?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/priorities?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/priorities?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/priorities/bulk_update_order', {"project": 1, "bulk_priorities": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/priorities/bulk_update_order', {"project": 100, "bulk_priorities": [[1, 2], [2, 1]]}).respond(400)
        httpBackend.whenGET('http://localhost:8000/api/v1/severities?project=1').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/severities?project=1&test=test').respond(200)
        httpBackend.whenGET('http://localhost:8000/api/v1/severities?project=100').respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/severities?', {"test": "test"}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/severities?', {"test": "bad"}).respond(400)
        httpBackend.whenPOST('http://localhost:8000/api/v1/severities/bulk_update_order', {"project": 1, "bulk_severities": [[1, 2], [2, 1]]}).respond(200)
        httpBackend.whenPOST('http://localhost:8000/api/v1/severities/bulk_update_order', {"project": 100, "bulk_severities": [[1, 2], [2, 1]]}).respond(400)

    describe 'resource service', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

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

            httpBackend.expectGET('http://localhost:8000/api/v1/resolver')
            promise = resource.resolve({})
            promise.should.be.fullfilled
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

        it 'should allow to get a project issues filters data', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/projects/1/issue_filters_data')
            promise = resource.getIssuesFiltersData(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/projects/100/issue_filters_data')
            promise = resource.getIssuesFiltersData(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a membership', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/memberships?', {"test": "test"})
            promise = resource.createMembership({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/memberships?', {"test": "bad"})
            promise = resource.createMembership({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a project roles', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/roles?project=1')
            promise = resource.getRoles(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/roles?project=100')
            promise = resource.getRoles(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a role', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/roles?', {"test": "test", "project": 1})
            promise = resource.createRole(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/roles?', {"test": "bad", "project": 1})
            promise = resource.createRole(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get all the milestones of a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/milestones?project=1')
            promise = resource.getMilestones(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/milestones?project=100')
            promise = resource.getMilestones(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get one milestone', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/milestones/1?project=1')
            promise = resource.getMilestone(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/milestones/100?project=1')
            promise = resource.getMilestone(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a milestone stats', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/milestones/1/stats')
            promise = resource.getMilestoneStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/milestones/100/stats')
            promise = resource.getMilestoneStats(100)
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

        it 'should allow to get the userstories of a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?project=1')
            promise = resource.getUserStories(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?project=100')
            promise = resource.getUserStories(100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the userstories of a milestone', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?milestone=1&project=1')
            promise = resource.getMilestoneUserStories(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories?milestone=100&project=1')
            promise = resource.getMilestoneUserStories(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a userstory', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories/1?project=1')
            promise = resource.getUserStory(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories/100?project=1')
            promise = resource.getUserStory(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a userstory history', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstories/1/historical')
            promise = resource.getUserStoryHistorical(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories/100/historical')
            promise = resource.getUserStoryHistorical(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstories/1/historical?filter=test')
            promise = resource.getUserStoryHistorical(1, {"filter": "test"})
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to get the tasks of a milestone', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/tasks?milestone=1&project=1')
            promise = resource.getTasks(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/tasks?milestone=100&project=1')
            promise = resource.getTasks(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/tasks?project=1')
            promise = resource.getTasks(1)
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to get the issues of a project', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issues?project=1')
            promise = resource.getIssues(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issues?project=100')
            promise = resource.getIssues(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issues?filters=test&project=1')
            promise = resource.getIssues(1, {"filters": "test"})
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to get a issue', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issues/1?project=1')
            promise = resource.getIssue(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issues/100?project=1')
            promise = resource.getIssue(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a issue history', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issues/1/historical')
            promise = resource.getIssueHistorical(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issues/100/historical')
            promise = resource.getIssueHistorical(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issues/1/historical?filter=test')
            promise = resource.getIssueHistorical(1, {"filter": "test"})
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to get a task', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/tasks/1?project=1')
            promise = resource.getTask(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/tasks/100?project=1')
            promise = resource.getTask(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a task history', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/tasks/1/historical')
            promise = resource.getTaskHistorical(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/tasks/100/historical')
            promise = resource.getTaskHistorical(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/tasks/1/historical?filter=test')
            promise = resource.getTaskHistorical(1, {"filter": "test"})
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to search', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/search?get_all=false&project=1&text=test')
            promise = resource.search(1, "test", false)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/search?get_all=false&project=1&text=bad')
            promise = resource.search(1, "bad", false)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to users', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/users?project=1')
            promise = resource.getUsers(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/users?project=100')
            promise = resource.getUsers(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/users')
            promise = resource.getUsers()
            promise.should.be.fullfilled
            httpBackend.flush()

        it 'should allow to create a issue', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/issues', {"test": "test", "project": 1})
            promise = resource.createIssue(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/issues', {"test": "bad", "project": 1})
            promise = resource.createIssue(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a user story', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories?', {"test": "test"})
            promise = resource.createUserStory({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories?', {"test": "bad"})
            promise = resource.createUserStory({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a bulk of user stories', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories/bulk_create', {"test": "test", "projectId": 1})
            promise = resource.createBulkUserStories(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories/bulk_create', {"test": "bad", "projectId": 1})
            promise = resource.createBulkUserStories(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a bulk of tasks', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "test", "projectId": 1, "usId": 2})
            promise = resource.createBulkTasks(1, 2, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "bad", "projectId": 1, "usId": 2})
            promise = resource.createBulkTasks(1, 2, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a bulk of tasks', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "test", "projectId": 1, "usId": 2})
            promise = resource.createBulkTasks(1, 2, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks/bulk_create', {"test": "bad", "projectId": 1, "usId": 2})
            promise = resource.createBulkTasks(1, 2, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow update the user stories order in bulk', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories/bulk_update_order', {"projectId": 1, "bulkStories": [[1, 2], [2, 1]]})
            promise = resource.updateBulkUserStoriesOrder(1, [[1, 2], [2, 1]])
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/userstories/bulk_update_order', {"projectId": 100, "bulkStories": [[1, 2], [2, 1]]})
            promise = resource.updateBulkUserStoriesOrder(100, [[1, 2], [2, 1]])
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow set the milestone of a user story', inject (resource) ->
            httpBackend.expectPATCH('http://localhost:8000/api/v1/userstories/1', {"milestone": 2})
            promise = resource.setUsMilestone(1, 2)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPATCH('http://localhost:8000/api/v1/userstories/100', {"milestone": 1})
            promise = resource.setUsMilestone(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow create a milestone', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/milestones', {"project": 1, "test": "test"})
            promise = resource.createMilestone(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/milestones', {"project": 100, "test": "test"})
            promise = resource.createMilestone(100, {"test": "test"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a wiki page', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/wiki?project=1&slug=test')
            promise = resource.getWikiPage(1, "test")
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/wiki?project=1&slug=bad')
            promise = resource.getWikiPage(1, "bad")
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/wiki?project=1&slug=empty')
            promise = resource.getWikiPage(1, "empty")
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get a wiki page historical', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/wiki/test/historical')
            promise = resource.getWikiPageHistorical("test")
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/wiki/test/historical?filters=test')
            promise = resource.getWikiPageHistorical("test", {"filters": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/wiki/bad/historical?filters=test')
            promise = resource.getWikiPageHistorical("bad", {"filters": "test"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a task', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks?', {"test": "test"})
            promise = resource.createTask({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/tasks?', {"test": "bad"})
            promise = resource.createTask({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to restore a wiki page', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/wiki/test/restore?version=1')
            promise = resource.restoreWikiPage("test", 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/wiki/bad/restore?version=1')
            promise = resource.restoreWikiPage("bad", 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to create a wiki page', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/wiki', {"content": "test", "slug": "test-slug", "project": 1})
            promise = resource.createWikiPage(1, "test-slug", "test")
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST('http://localhost:8000/api/v1/wiki', {"content": "bad", "slug": "test-slug", "project": 1})
            promise = resource.createWikiPage(1, "test-slug", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the attachments of an issue', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issue-attachments?object_id=1&project=1')
            promise = resource.getIssueAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/issue-attachments?object_id=1&project=100')
            promise = resource.getIssueAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the attachments of a task', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/task-attachments?object_id=1&project=1')
            promise = resource.getTaskAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/task-attachments?object_id=1&project=100')
            promise = resource.getTaskAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the attachments of an issue', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstory-attachments?object_id=1&project=1')
            promise = resource.getUserStoryAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/userstory-attachments?object_id=1&project=100')
            promise = resource.getUserStoryAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the attachments of an issue', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/wiki-attachments?object_id=1&project=1')

            promise = resource.getWikiPageAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET('http://localhost:8000/api/v1/wiki-attachments?object_id=1&project=100')
            promise = resource.getWikiPageAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it 'should allow to get the site info', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/sites')
            promise = resource.getSiteInfo()
            promise.should.fullfilled
            httpBackend.flush()

        it 'should allow to get the user stories statuses', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/userstory-statuses?project=1')
            promise = resource.getUserStoryStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstory-statuses?project=1&test=test')
            promise = resource.getUserStoryStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/userstory-statuses?project=100')
            promise = resource.getUserStoryStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a user stories status', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/userstory-statuses?', {"test": "test"})
            promise = resource.createUserStoryStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/userstory-statuses?', {"test": "bad"})
            promise = resource.createUserStoryStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the user stories statuses orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/userstory-statuses/bulk_update_order', {"project": 1, "bulk_userstory_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkUserStoryStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/userstory-statuses/bulk_update_order', {"project": 100, "bulk_userstory_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkUserStoryStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the user stories points', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/points?project=1')
            promise = resource.getPoints(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/points?project=1&test=test')
            promise = resource.getPoints(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/points?project=100')
            promise = resource.getPoints(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a user stories status', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/points?', {"test": "test"})
            promise = resource.createPoints({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/points?', {"test": "bad"})
            promise = resource.createPoints({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the user stories points orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/points/bulk_update_order', {"project": 1, "bulk_points": [[1, 2], [2, 1]]})
            promise = resource.updateBulkPointsOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/points/bulk_update_order', {"project": 100, "bulk_points": [[1, 2], [2, 1]]})
            promise = resource.updateBulkPointsOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the tasks statuses', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/task-statuses?project=1')
            promise = resource.getTaskStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/task-statuses?project=1&test=test')
            promise = resource.getTaskStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/task-statuses?project=100')
            promise = resource.getTaskStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a tasks status', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/task-statuses?', {"test": "test"})
            promise = resource.createTaskStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/task-statuses?', {"test": "bad"})
            promise = resource.createTaskStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the tasks statuses orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/task-statuses/bulk_update_order', {"project": 1, "bulk_task_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkTaskStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/task-statuses/bulk_update_order', {"project": 100, "bulk_task_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkTaskStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the issues statuses', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issue-statuses?project=1')
            promise = resource.getIssueStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issue-statuses?project=1&test=test')
            promise = resource.getIssueStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issue-statuses?project=100')
            promise = resource.getIssueStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a issues status', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-statuses?', {"test": "test"})
            promise = resource.createIssueStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-statuses?', {"test": "bad"})
            promise = resource.createIssueStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the issues statuses orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-statuses/bulk_update_order', {"project": 1, "bulk_issue_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkIssueStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-statuses/bulk_update_order', {"project": 100, "bulk_issue_statuses": [[1, 2], [2, 1]]})
            promise = resource.updateBulkIssueStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the issues types', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/issue-types?project=1')
            promise = resource.getIssueTypes(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issue-types?project=1&test=test')
            promise = resource.getIssueTypes(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/issue-types?project=100')
            promise = resource.getIssueTypes(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a issues type', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-types?', {"test": "test"})
            promise = resource.createIssueType({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-types?', {"test": "bad"})
            promise = resource.createIssueType({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the issues types orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-types/bulk_update_order', {"project": 1, "bulk_issue_types": [[1, 2], [2, 1]]})
            promise = resource.updateBulkIssueTypesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/issue-types/bulk_update_order', {"project": 100, "bulk_issue_types": [[1, 2], [2, 1]]})
            promise = resource.updateBulkIssueTypesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the priorities', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/priorities?project=1')
            promise = resource.getPriorities(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/priorities?project=1&test=test')
            promise = resource.getPriorities(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/priorities?project=100')
            promise = resource.getPriorities(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a priority', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/priorities?', {"test": "test"})
            promise = resource.createPriority({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/priorities?', {"test": "bad"})
            promise = resource.createPriority({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the priorities orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/priorities/bulk_update_order', {"project": 1, "bulk_priorities": [[1, 2], [2, 1]]})
            promise = resource.updateBulkPrioritiesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/priorities/bulk_update_order', {"project": 100, "bulk_priorities": [[1, 2], [2, 1]]})
            promise = resource.updateBulkPrioritiesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to get the severities', inject (resource) ->
            httpBackend.expectGET('http://localhost:8000/api/v1/severities?project=1')
            promise = resource.getSeverities(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/severities?project=1&test=test')
            promise = resource.getSeverities(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET('http://localhost:8000/api/v1/severities?project=100')
            promise = resource.getSeverities(100)
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to create a severity', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/severities?', {"test": "test"})
            promise = resource.createSeverity({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/severities?', {"test": "bad"})
            promise = resource.createSeverity({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it 'should allow to bulk update the severities orders', inject (resource) ->
            httpBackend.expectPOST('http://localhost:8000/api/v1/severities/bulk_update_order', {"project": 1, "bulk_severities": [[1, 2], [2, 1]]})
            promise = resource.updateBulkSeveritiesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST('http://localhost:8000/api/v1/severities/bulk_update_order', {"project": 100, "bulk_severities": [[1, 2], [2, 1]]})
            promise = resource.updateBulkSeveritiesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()
