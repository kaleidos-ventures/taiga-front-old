describe 'authController', ->
    beforeEach(module('taiga.controllers.auth'))
    describe 'LoginController', ->
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $location, $routeParams, resource, $gmAuth, $i18next, $favico) ->
            scope = $rootScope.$new()
            ctrl = $controller('LoginController', {
                $scope: scope,
                $rootScope: $rootScope,
                $location: $location,
                $routeParams: $routeParams,
                resource: resource,
                $gmAuth: $gmAuth,
                $i18next: $i18next,
                $favico: $favico
            })
        ))

        it 'should have section login', ->
            expect(ctrl.section).toEqual('login')
