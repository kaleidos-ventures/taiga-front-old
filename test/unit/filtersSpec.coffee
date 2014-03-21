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
