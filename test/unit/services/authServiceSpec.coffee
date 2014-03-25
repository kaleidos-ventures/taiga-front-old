describe 'authService', ->
    rootScope = null

    beforeEach(module('taiga.services.auth'))

    describe '$gmAuth', ->
        it('should allow to set and get the token', inject(($gmAuth) ->
            $gmAuth.setToken('test-token')
            expect($gmAuth.getToken()).toEqual('test-token')
        ))

        #it('should allow to set and get the user', inject(($gmAuth, $rootScope) ->
        #    rootScope = $rootScope.$new()
        #    testUser = { test: "test" }
        #    signalReceived = false
        #    rootScope.on "i18n:change", ->
        #        signalReceived = true
        #    $gmAuth.setUser(testUser)
        #    expect($gmAuth.getUser()).toEqual(testUser)
        #    expect(rootScope.getUser()).toEqual(testUser)
        #    expect($signalReceived).toEqual(true)
        #))

        #it('should allow to check if the user is authenticated', inject(($gmAuth) ->
        #    expect($gmAuth.isAuthenticated()).toEqual(false)
        #    testUser = { test: "test" }
        #    $gmAuth.setUser(testUser)
        #    expect($gmAuth.isAuthenticated()).toEqual(true)
        #))
