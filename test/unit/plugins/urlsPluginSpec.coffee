describe 'gmUrls', ->
    provider = null

    beforeEach ->
        fakeModule = angular.module('fake', ->)
        fakeModule.config ($gmUrlsProvider) ->
            provider = $gmUrlsProvider
        module('gmUrls', 'fake')

    describe 'UrlsProvider', ->
        it 'should allow to register urls in various namespaces', inject ($gmUrls) ->
            expect(-> provider.setUrls("test")).to.throw(Error, "wrong arguments to setUrls")
            expect($gmUrls["test"]).to.be.undefined
            provider.setUrls "test", {
                "url1": "/resolved/url/1"
                "url-with-params": "/url/with/params/%s/%s"
            }
            expect($gmUrls["test"]).to.be.a('function')
            expect($gmUrls["test2"]).to.be.undefined
            provider.setUrls "test2", {
                "url2": "/resolved/url/2"
                "url-with-params": "/url/with/params/%s/%s"
            }
            expect($gmUrls["test2"]).to.be.a('function')

        it 'should allow set the urls host by namespace', inject ($gmUrls) ->
            expect(-> $gmUrls.setHost("test")).to.throw(Error, "wrong arguments to setHost")
            $gmUrls.setHost('test', 'localhost', 'http')
            expect($gmUrls.data.host.test).to.be.equal('localhost')
            expect($gmUrls.data.scheme.test).to.be.equal('http')

        it 'should allow query for an url', inject ($gmUrls) ->
            $gmUrls.setHost('test', 'localhost', 'http')
            expect($gmUrls.test('url1')).to.be.equal('http://localhost/resolved/url/1')
            $gmUrls.setHost('test2', 'localhost2', 'https')
            expect($gmUrls.test2('url2')).to.be.equal('https://localhost2/resolved/url/2')

        it 'should allow query for an url with params', inject ($gmUrls) ->
            $gmUrls.setHost('test', 'localhost', 'http')
            expect($gmUrls.test('url-with-params', "test1", "test2")).to.be.equal('http://localhost/url/with/params/test1/test2')
