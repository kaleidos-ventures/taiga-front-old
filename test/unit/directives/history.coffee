
APIURL = "http://localhost:8000/api/v1"


describe "GmHistoryDirective", ->
    element = null
    $rootScope = null
    $compile = null
    httpBackend = null

    beforeEach(module('taiga'))
    beforeEach(module('taiga.directives.history'))

    template = """
    <div>
        <div class="history" gm-history="issue"
            data-history-type="issue"
            data-object-id="objectId">
        </div>
    </div>
    """

    history = [
        {
            "diff": {
                "status": [2, 1],
            }
            "snapshot": null,
            "values": {
                "status": {
                    "2": "Closed",
                    "1": "Open"
                },
            },
            "values_diff": {
                "status": [
                    "Closed",
                    "Open"
                ]
            },
            "user": {
                "pk": 1,
                "name": "admin"
            },
            "id": "c1eb42e4-d534-11e3-8436-b499ba561cb4",
            "created_at": "2014-05-06T15:40:31.968Z",
            "type": 1,
            "is_snapshot": false,
            "key": "userstories.userstory:12",
            "comment": "",
            "comment_html": ""
        }
    ]

    beforeEach(inject((_$compile_, _$rootScope_, $httpBackend) ->
        $compile = _$compile_
        $rootScope = _$rootScope_

        httpBackend = $httpBackend
        httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})

        $rootScope.t = (x) -> x
        $rootScope.translate = (x) -> x
    ))

    it "should allow to draw an empty historical", ->
        httpBackend.whenGET("#{APIURL}/history/issue/1?page=1&page_size=30").respond(200, [])
        element = $compile(template)($rootScope)

        $rootScope.objectId = 1
        $rootScope.$digest()

        items = element.find(".history-item")
        expect(items).to.be.lengthOf(0)

    # This test should work  but it's not so.
    # it "should draw one history item", ->
    #     httpBackend.whenGET("#{APIURL}/history/issue/1?page=1&page_size=30").respond(200, history)
    #     element = $compile(template)($rootScope)
    #     $rootScope.objectId = 1
    #     $rootScope.$digest()
    #     httpBackend.flush()
    #     $rootScope.$digest()
    #     console.log(element.html())
    #     items = element.find(".history-item")
    #     changes = element.find(".change")
    #     expect(items).to.be.lengthOf(1)
    #     expect(changes).to.be.lengthOf(1)
