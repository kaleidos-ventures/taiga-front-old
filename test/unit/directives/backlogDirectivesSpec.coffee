beforeEach(module('taiga.directives.backlog'))

describe "GmDoomlineDirective", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
    <div gm-doomline gm-doomline-element-selector=".test-element" gm-doomline-watch="test">
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
        $rootScope.projectStats = {
            total_points: 100
            assigned_points: 90
        }
        $rootScope.us = {total_points: 5}
    ))

    it "should select put a line on the correct position", ->
        $compile(element)($rootScope)
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('doomline')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[6]).hasClass('test-element')).to.be.true

    it "should redraw the line when the doomline:redraw signal is emitted", ->
        $compile(element)($rootScope)

        angular.element(element.find("div")[0]).remove()
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('doomline')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

        $rootScope.$broadcast("doomline:redraw")
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('doomline')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

    it "should redraw the line when the gmDoomlineWatch is changed", ->
        $compile(element)($rootScope)

        angular.element(element.find("div")[0]).remove()
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('doomline')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

        $rootScope.$apply ->
            $rootScope.test = "test"
        expect(angular.element(element.find("div")[0]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[1]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[2]).hasClass('doomline')).to.be.true
        expect(angular.element(element.find("div")[3]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[4]).hasClass('test-element')).to.be.true
        expect(angular.element(element.find("div")[5]).hasClass('test-element')).to.be.true

    it "shouldn't draw the line on a list with less or equal items than the WIP", ->
        $compile(element)($rootScope)
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()
        angular.element(element.find("div")[0]).remove()

        $rootScope.$broadcast("doomline:redraw")
        expect(element.find("div.doomline")).to.have.length(0)

    it "shouldn't draw the line if not projectStats in the scope", ->
        $rootScope.projectStats = null
        $compile(element)($rootScope)

        expect(element.find("div.doomline")).to.have.length(0)

    it "should count element without us", ->
        $rootScope.us = null
        $compile(element)($rootScope)

        expect(element.find("div.doomline")).to.have.length(0)
