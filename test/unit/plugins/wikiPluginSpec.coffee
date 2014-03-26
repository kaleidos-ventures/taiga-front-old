describe 'gmWiki', ->
    beforeEach(module('gmWiki'))

    describe 'gmWiki service', ->
        it 'should allow to render in wiki format', inject (gmWiki) ->
            expect(gmWiki.render('**test**')).to.be.equal('<p><strong>test</strong></p>\n')

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
