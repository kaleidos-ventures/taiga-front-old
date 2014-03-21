describe 'commonDirectives', ->
    beforeEach(module('taiga.directives.common'))
    describe 'GmHeaderMenuDirective', ->
        element = null
        beforeEach(inject(($compile, $rootScope) ->
            element = angular.element("""
                <ul gm-header-menu>
                    <li class='backlog'></li>
                    <li class='kanban'></li>
                    <li class='issues'></li>
                    <li class='questions'></li>
                    <li class='wiki'></li>
                    <li class='admin'></li>
                </ul>""")
        ))
        it('should select the page section li', inject(($compile, $rootScope) ->
            $rootScope.pageSection = "backlog"
            $compile(element)($rootScope)
            expect(element.find(".backlog").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "kanban"
            $compile(element)($rootScope)
            expect(element.find(".kanban").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "issues"
            $compile(element)($rootScope)
            expect(element.find(".issues").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "questions"
            $compile(element)($rootScope)
            expect(element.find(".questions").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "wiki"
            $compile(element)($rootScope)
            expect(element.find(".wiki").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "admin"
            $compile(element)($rootScope)
            expect(element.find(".admin").hasClass('selected')).toBe(true)

            $rootScope.pageSection = "backlog"
            $compile(element)($rootScope)
            expect(element.find(".kanban").hasClass('selected')).toBe(false)
        ))
