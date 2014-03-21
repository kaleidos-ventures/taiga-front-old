describe 'filter', ->
    beforeEach(module('taiga.filters'))
    describe 'lowercase', ->
        it('should change the case to all lower case', inject((lowercaseFilter) ->
            expect(lowercaseFilter('TAIGA')).toEqual('taiga')
            expect(lowercaseFilter('Taiga')).toEqual('taiga')
            expect(lowercaseFilter('taiga')).toEqual('taiga')
            expect(lowercaseFilter('TaIgA')).toEqual('taiga')
        ))

    describe 'capitalize', ->
        it('should change the case to capitalize case', inject((capitalizeFilter) ->
            expect(capitalizeFilter('TAIGA')).toEqual('Taiga')
            expect(capitalizeFilter('Taiga')).toEqual('Taiga')
            expect(capitalizeFilter('taiga')).toEqual('Taiga')
            expect(capitalizeFilter('TaIgA')).toEqual('Taiga')
        ))

    describe 'slugify', ->
        it('should convert a string in a slug', inject((slugifyFilter) ->
            expect(slugifyFilter('test')).toEqual('test')
            expect(slugifyFilter('Test')).toEqual('test')
            expect(slugifyFilter('test two')).toEqual('test-two')
            expect(slugifyFilter('test_three')).toEqual('test-three')
            expect(slugifyFilter('testñfour')).toEqual('testnfour')
        ))

    describe 'truncate', ->
        it('should truncate a word', inject((truncateFilter) ->
            expect(truncateFilter('test of truncation', 20)).toEqual('test of truncation')
            expect(truncateFilter('test of truncation', 10)).toEqual('test of...')
        ))
