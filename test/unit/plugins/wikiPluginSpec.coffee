describe 'gmWiki', ->
    beforeEach(module('taiga'))
    beforeEach(module('gmWiki'))
    httpBackend = null

    beforeEach inject ($httpBackend) ->
        httpBackend = $httpBackend
        httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})

    describe 'gmWiki service', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should allow to request a rendering in wiki format', inject (gmWiki) ->
            httpBackend.expectPOST("http://localhost:8000/api/v1/wiki/render", {project_id: 1, content: "**test**"}).respond(200, {data: "<strong>test</strong>"})
            promise = gmWiki.render(1, '**test**')
            httpBackend.flush()
            promise.should.be.fulfilled

    describe 'gmMarkitup directive', ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should allow to render in wiki format', inject ($compile, $rootScope) ->
            scope = $rootScope.$new()
            element = angular.element('<p gm-markitup></p>')
            $compile(element)(scope)
            expect(element.hasClass("markItUpEditor")).to.be.true
