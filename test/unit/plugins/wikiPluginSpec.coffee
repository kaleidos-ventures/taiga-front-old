describe 'gmWiki', ->
    beforeEach(module('taiga'))
    beforeEach(module('gmWiki'))

    beforeEach inject ($httpBackend) ->
        $httpBackend.whenGET('http://localhost:8000/api/v1/sites').respond(200, {test: "test"})

    describe 'gmWiki service', ->
        it 'should allow to render in wiki format', inject (gmWiki) ->
            expect(gmWiki.render('**test**')).to.be.equal('<p><strong>test</strong></p>\n')

        it 'should allow to render emojis in the wiki', inject (gmWiki) ->
            expect(gmWiki.render(':plus1:')).to.be.equal('<p><img title=\'plus1\' src=\'/img/emoticons/plus1.png\' /></p>\n')
            expect(gmWiki.render(':no-emoji:')).to.be.equal('<p>:no-emoji:</p>\n')

        it 'should allow to render links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/link">test</a></p>\n'
            expect(gmWiki.render('[test](/link)')).to.be.equal(expectedResult)

        it 'should allow to render wiki pages links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/#/project/test/wiki/test">test</a></p>\n'
            expect(gmWiki.render('[test](test)')).to.be.equal(expectedResult)

        it 'should allow to render us links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/#/project/test/user-story/1?">us</a></p>\n'
            expect(gmWiki.render('[us](:us:1)')).to.be.equal(expectedResult)

        it 'should allow to render task links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/#/project/test/tasks/1">task</a></p>\n'
            expect(gmWiki.render('[task](:task:1)')).to.be.equal(expectedResult)

        it 'should allow to render issue links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/#/project/test/issues/1?">issue</a></p>\n'
            expect(gmWiki.render('[issue](:issue:1)')).to.be.equal(expectedResult)

        it 'should allow to render issue links in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><a href="/#/project/test/taskboard/1">sprint</a></p>\n'
            expect(gmWiki.render('[sprint](:sprint:1)')).to.be.equal(expectedResult)

        it 'should allow to render attachment images in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><img src="http://localhost:8000/media/attachment-files/test/wikipage/test.png" alt="test"></p>\n'
            expect(gmWiki.render('![test](:att:test.png)')).to.be.equal(expectedResult)

        it 'should allow to render attachment images in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            $routeParams.pslug = "test"
            expectedResult = '<p><img src="/test.png" alt="test"></p>\n'
            expect(gmWiki.render('![test](/test.png)')).to.be.equal(expectedResult)
            expectedResult = '<p><img src="test.png" alt="test"></p>\n'
            expect(gmWiki.render('![test](test.png)')).to.be.equal(expectedResult)

        it 'should allow to render code in the wiki', inject (gmWiki, $routeParams, $rootScope) ->
            expectedResult = '<pre><code class="lang-python">print(<span class="hljs-string">"test"</span>)\n</code></pre>\n'
            expect(gmWiki.render('```python\nprint("test")\n```')).to.be.equal(expectedResult)
            expectedResult = '<pre><code><span class="hljs-function"><span class="hljs-title">print</span><span class="hljs-params">(<span class="hljs-string">"test"</span>)</span></span>\n</code></pre>'
            expect(gmWiki.render('```\nprint("test")\n```')).to.be.equal(expectedResult)

    describe 'wiki filter', ->
        it 'should allow to render in wiki format', inject (wikiFilter) ->
            expect(wikiFilter('**test**')).to.be.equal('<p><strong>test</strong></p>\n')

    describe 'gmRenderMarkdow directive', ->
        it 'should allow to render in wiki format', inject ($compile, $rootScope) ->
            scope = $rootScope.$new()
            scope.testText = "**test**"
            element = angular.element('<p gm-render-markdown="testText"></p>')
            $compile(element)(scope)
            expect(element.html()).to.be.equal('<p><strong>test</strong></p>\n')

            scope.testText = "**test2**"
            scope.$digest()
            expect(element.html()).to.be.equal('<p><strong>test2</strong></p>\n')

            element = angular.element('<p gm-render-markdown>**test3**</p>')
            $compile(element)(scope)
            expect(element.html()).to.be.equal('<p><strong>test3</strong></p>\n')

    describe 'gmMarkitup directive', ->
        it 'should allow to render in wiki format', inject ($compile, $rootScope) ->
            scope = $rootScope.$new()
            element = angular.element('<p gm-markitup></p>')
            $compile(element)(scope)
            expect(element.hasClass("markItUpEditor")).to.be.true
