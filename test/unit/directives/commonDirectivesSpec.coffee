beforeEach(module('taiga.directives.common'))
beforeEach(module('taiga.directives.generic'))

describe "GmSelectedFiltersRendererDirective", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
    <div class="tags-list-sbox"
        gm-selected-filters-renderer="selectedFilters"
        gm-toggle-filter-callback="toggleFilter(tag)">
    </div>
    """

    lastToggledFilter = null

    beforeEach(inject((_$compile_, _$rootScope_) ->
        $compile = _$compile_
        $rootScope = _$rootScope_
        $rootScope.selectedFilters = []

        dom = angular.element.parseHTML(template)
        element = angular.element(dom)
    ))

    it "test simple render", ->
        element = $compile(template)($rootScope)

        $rootScope.selectedFilters = [{id: 1, name: "foo", type: "bar"}]
        $rootScope.$digest()

        expect(element.find(".tag").length).to.be.equal(1)

    it "simple multiple render", ->
        element = $compile(template)($rootScope)

        $rootScope.selectedFilters = [{id: 1, name: "foo", type: "bar"},
                                      {id: 2, name: "foo", type: "bar"}]
        $rootScope.$digest()

        expect(element.find(".tag").length).to.be.equal(2)

    it "remove filter on click", ->
        element = $compile(template)($rootScope)
        lastToggledFilter = null

        $rootScope.selectedFilters = [{id: 1, name: "foo", type: "bar"}]
        $rootScope.toggleFilter = (tag) ->
            lastToggledFilter = tag
            $rootScope.selectedFilters = []

        $rootScope.$digest()

        element.find(".tag").click()
        $rootScope.$digest()

        expect(element.find(".tag").length).to.be.equal(0)


describe "GmHeaderMenuDirective", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
    <ul gm-header-menu>
        <li class='backlog'></li>
        <li class='kanban'></li>
        <li class='issues'></li>
        <li class='questions'></li>
        <li class='wiki'></li>
        <li class='admin'></li>
    </ul>
    """

    beforeEach(inject((_$compile_, _$rootScope_) ->
        element = angular.element(template)
        $compile = _$compile_
        $rootScope = _$rootScope_
    ))

    it "should select the page section li", ->
        $rootScope.pageSection = "backlog"
        $compile(element)($rootScope)
        expect(element.find(".backlog").hasClass('selected')).to.be.true

        $rootScope.pageSection = "kanban"
        $compile(element)($rootScope)
        expect(element.find(".kanban").hasClass('selected')).to.be.true

        $rootScope.pageSection = "issues"
        $compile(element)($rootScope)
        expect(element.find(".issues").hasClass('selected')).to.be.true

        $rootScope.pageSection = "questions"
        $compile(element)($rootScope)
        expect(element.find(".questions").hasClass('selected')).to.be.true

        $rootScope.pageSection = "wiki"
        $compile(element)($rootScope)
        expect(element.find(".wiki").hasClass('selected')).to.be.true

        $rootScope.pageSection = "admin"
        $compile(element)($rootScope)
        expect(element.find(".admin").hasClass('selected')).to.be.true

        $rootScope.pageSection = "backlog"
        $compile(element)($rootScope)
        expect(element.find(".kanban").hasClass('selected')).to.be.false

        $rootScope.pageSection = "other"
        $compile(element)($rootScope)
        expect(element.find(".selected")).to.have.length(0)

describe "GmKanbanWip", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
    <div gm-kanban-wip="3" gm-kanban-wip-element-selector=".test-element" gm-kanban-watch="test">
        <div class='test-element'></div>
        <div class='test-element'></div>
        <div class='test-element'></div>
        <div class='test-element'></div>
        <div class='test-element'></div>
        <div class='test-element'></div>
    </div>
    """

    beforeEach(inject((_$compile_, _$rootScope_) ->
        element = angular.element(template)
        $compile = _$compile_
        $rootScope = _$rootScope_
    ))

    it "should select put a line on the correct position", ->
        $compile(element)($rootScope)
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('wipline')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[6]).hasClass('test-element')).to.be.true

    it "should redraw the line when the wipline:redraw signal is emitted", ->
        $compile(element)($rootScope)
        angular.element(element.find("div")[0]).remove()
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('wipline')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

        $rootScope.$broadcast("wipline:redraw")
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('wipline')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

    it "should redraw the line when the watched model is changed", ->
        $compile(element)($rootScope)
        angular.element(element.find("div")[0]).remove()
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('wipline')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

        $rootScope.$apply ->
            $rootScope.test = "test"
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('wipline')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

    it "shouldn't draw the line on a list with less or equal items than the WIP", ->
        $compile(element)($rootScope)
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()

        $rootScope.$broadcast("wipline:redraw")
        expect(element.find("div.wipline")).to.have.length(0)

        angular.element(element.find("div")[0]).remove()

        $rootScope.$broadcast("wipline:redraw")
        expect(element.find("div.wipline")).to.have.length(0)

        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()

        expect(element.find("div.wipline")).to.have.length(0)
