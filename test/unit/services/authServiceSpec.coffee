describe 'authService', ->
    beforeEach(module('taiga.services.auth'))
    beforeEach(module('taiga.services.model'))
    beforeEach(module('gmStorage'))
    beforeEach(module('gmUrls'))
    describe '$gmAuth', ->
        it('should allow to set and get the token', inject(($gmAuth) ->
            $gmAuth.setToken('test-token')
            expect($gmAuth.getToken()).toEqual('test-token')
        ))

