template = """
<div
    class="issue-sortable-field issue-severity"
    ng-model="ordering"
    gm-issues-sorted-by="severity">
    Severity
</div>
"""


describe "IssuesOrderByDirective", ->
    $rootScope = null
    $compile = null
    $gmFilters = null

    beforeEach(module("taiga.services.tags"))
    beforeEach(module("taiga.directives.issues"))

    beforeEach(inject((_$compile_, _$rootScope_, _$gmFilters_) ->
        $compile = _$compile_
        $rootScope = _$rootScope_
        $gmFilters = _$gmFilters_
    ))

    it "Test simple rendering 01", ->
        $gmFilters.setOrdering(1, "issues-ordering", {orderBy: "severity", isReverse: true})

        element = $compile(template)($rootScope);

        $rootScope.projectId = 1
        $rootScope.$digest()

        expect(element.is(".icon-chevron-up")).to.be.true

    it "Test simple rendering 02", ->
        $gmFilters.setOrdering(1, "issues-ordering", {orderBy: "severity", isReverse: false})

        element = $compile(template)($rootScope);

        $rootScope.projectId = 1
        $rootScope.$digest()

        expect(element.is(".icon-chevron-down")).to.be.true

