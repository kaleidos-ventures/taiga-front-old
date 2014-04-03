describe 'searchController', ->

    beforeEach(module('taiga'))
    beforeEach(module('taiga.controllers.search'))

    describe 'SearchController', ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $routeParams) ->
            scope = $rootScope.$new()
            $routeParams.pslug = "ptest"
            $routeParams.term = "term-test"
            ctrl = $controller('SearchController', {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})
            httpBackend.whenGET("http://localhost:8000/api/v1/resolver?project=ptest").respond(200, {project: 1})
            httpBackend.whenGET("http://localhost:8000/api/v1/projects/1?").respond(200, {id: 1, ref: "2", points: []})
            httpBackend.whenGET(
                "http://localhost:8000/api/v1/search?get_all=false&project=1&text=term-test"
            ).respond(200, {count: 10, issues: ["test1"], tasks: ["test2", "test3"], userstories: ["test4"]})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it 'should have section login', ->
            expect(ctrl.section).to.be.equal('search')

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to translate the result type a name', ->
            expect(ctrl.translateResultType('userstories')).to.be.equal("User Stories")
            expect(ctrl.translateResultType('tasks')).to.be.equal("Tasks")
            expect(ctrl.translateResultType('issues')).to.be.equal("Issues")
            expect(ctrl.translateResultType('wikipages')).to.be.equal("Wiki Pages")
            expect(ctrl.translateResultType('other')).to.be.equal("other")

        it 'should allow to translate the type a url', ->
            expect(ctrl.translateTypeUrl('userstories', 'test', {ref: "1"})).to.be.equal("/#/project/test/user-story/1?")
            expect(ctrl.translateTypeUrl('tasks', 'test', {ref: "1"})).to.be.equal("/#/project/test/tasks/1")
            expect(ctrl.translateTypeUrl('issues', 'test', {ref: "1"})).to.be.equal("/#/project/test/issues/1?")
            expect(ctrl.translateTypeUrl('wikipages', 'test', {slug: "test"})).to.be.equal("/#/project/test/wiki/test")
            expect(ctrl.translateTypeUrl('other', 'test', {ref: "1"})).to.be.equal("")

        it 'should allow to translate the type a title', ->
            expect(ctrl.translateTypeTitle('userstories', {subject: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeTitle('tasks', {subject: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeTitle('issues', {subject: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeTitle('wikipages', {slug: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeTitle('other', {subject: "test"})).to.be.equal("")

        it 'should allow to translate the type a title', ->
            expect(ctrl.translateTypeDescription('userstories', {description: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeDescription('tasks', {description: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeDescription('issues', {description: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeDescription('wikipages', {content: "test"})).to.be.equal("test")
            expect(ctrl.translateTypeDescription('other', {description: "test"})).to.be.equal("")

        it 'should allow set an active type', ->
            ctrl.scope.activeType = ""
            ctrl.setActiveType("tasks")
            expect(ctrl.scope.activeType).to.be.equal("tasks")

        it 'should allow check if a type is active', ->
            ctrl.scope.activeType = "tasks"
            expect(ctrl.isTypeActive("tasks")).to.be.true
            expect(ctrl.isTypeActive("issues")).to.be.false
