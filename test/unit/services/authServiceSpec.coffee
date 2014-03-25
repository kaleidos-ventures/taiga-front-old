describe 'authService', ->
    rootScope = null

    beforeEach(module('taiga.services.auth'))

    describe '$gmAuth', ->
        it('should allow to set and get the token', inject(($gmAuth) ->
            $gmAuth.setToken('test-token')
            expect($gmAuth.getToken()).to.be.equal('test-token')
        ))

        it('should allow to set and get the user', inject(($gmAuth, $rootScope, $model) ->
            $gmAuth.unsetUser()
            rootScope = $rootScope.$new()
            testUser = new $model.cls({ test: "test" })

            signalReceived = false
            rootScope.$on "i18n:change", ->
                signalReceived = true

            $gmAuth.setUser(testUser)
            expect($gmAuth.getUser().getAttrs()).to.be.deep.equal(testUser.getAttrs())
            expect(rootScope.auth.getAttrs()).to.be.deep.equal(testUser.getAttrs())
            expect(signalReceived).to.be.true
        ))

        it('should allow to check if the user is authenticated', inject(($gmAuth, $model) ->
            $gmAuth.unsetUser()
            expect($gmAuth.isAuthenticated()).to.be.false
            testUser = new $model.cls({ test: "test" })
            $gmAuth.setUser(testUser)
            expect($gmAuth.isAuthenticated()).to.be.true
        ))
