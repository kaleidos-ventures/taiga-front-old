describe "IssuesOrderByDirective", ->
    $rootScope = null
    $compile = null
    $gmFilters = null

    refreshCalledCounter = 0
    refresh = ->
        refreshCalledCounter += 1

    template = """
    <div
        class="issue-sortable-field issue-severity"
        ng-model="ordering"
        gm-refresh-callback="refresh()"
        gm-issues-sorted-by="severity">
        Severity
    </div>
    """

    beforeEach(module("taiga.services.filters"))
    beforeEach(module("taiga.directives.issues"))

    beforeEach(inject((_$compile_, _$rootScope_, _$gmFilters_) ->
        $compile = _$compile_
        $rootScope = _$rootScope_
        $gmFilters = _$gmFilters_

        refreshCalledCounter = 0
        $rootScope.refresh = refresh
    ))

    it "Test simple rendering 01", ->
        $gmFilters.setOrdering(1, "issues", {orderBy: "severity", isReverse: true})

        element = $compile(template)($rootScope);

        $rootScope.projectId = 1
        $rootScope.$digest()

        expect(element.is(".icon-chevron-up")).to.be.true
        expect(refreshCalledCounter).to.be.equal(0)

    it "Test simple rendering 02", ->
        $gmFilters.setOrdering(1, "issues", {orderBy: "severity", isReverse: false})

        element = $compile(template)($rootScope);

        $rootScope.projectId = 1
        $rootScope.$digest()

        expect(element.is(".icon-chevron-down")).to.be.true
        expect(refreshCalledCounter).to.be.equal(0)

    it "Test rendering with events", ->
        $gmFilters.setOrdering(1, "issues", {orderBy: "severity", isReverse: false})

        element = $compile(template)($rootScope);

        $rootScope.projectId = 1
        $rootScope.$digest()

        element.click()

        $rootScope.$digest()

        expect(element.is(".icon-chevron-up")).to.be.true
        expect(refreshCalledCounter).to.be.equal(1)

        result = $gmFilters.getOrdering(1, "issues")
        expect(result.isReverse).to.be.true
