cby = root['by']

describe 'Login Scenario', ->
    browser.get('index.html')

    describe 'login', ->
        ptor = null

        beforeEach ->
            browser.get('index.html#/login')
            ptor = protractor.getInstance()

        it 'should render login form when user navigates to /login', ->
            expect(ptor.isElementPresent(cby.id('login-form'))).toBe(true)
