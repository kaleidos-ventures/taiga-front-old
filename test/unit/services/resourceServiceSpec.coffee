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
