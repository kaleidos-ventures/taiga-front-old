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

    describe 'sizeFormat', ->
        it('should return the size in human readable format', inject((sizeFormatFilter) ->
            expect(sizeFormatFilter(1000, 1)).toEqual('1000.0 bytes')
            expect(sizeFormatFilter(1024, 1)).toEqual('1.0 KB')
            expect(sizeFormatFilter(1024*1024, 1)).toEqual('1.0 MB')
            expect(sizeFormatFilter(1024*1024*1024, 1)).toEqual('1.0 GB')
            expect(sizeFormatFilter(1024*1024*1024*1024, 1)).toEqual('1.0 TB')
            expect(sizeFormatFilter(1024*1024*1024*1024*1024, 1)).toEqual('1.0 PB')
            expect(sizeFormatFilter(1024*1024*1024*1024*1024*1024, 1)).toEqual('1024.0 PB')

            expect(sizeFormatFilter(2*1024*1024+10, 1)).toEqual('2.0 MB')
        ))
