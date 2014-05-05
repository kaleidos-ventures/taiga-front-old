describe "PopoverDirectivesTests", ->
    $rootScope = null
    $compile = null
    $gmFilters = null

    refreshCalledCounter = 0
    lastCallbackResult = null

    okCallback =  (_, id) ->
        refreshCalledCounter += 1
        lastCallbackResult = id

    template = """
    <div
        class="issue-sortable-field issue-severity"
        ng-model="ordering"
        gm-refresh-callback="refresh()"
        gm-issues-sorted-by="severity">
        Severity
    </div>
    """

    beforeEach(module("taiga.directives.popovers"))
    beforeEach(module("ngSanitize"))
    beforeEach(module("gmWiki"))

    beforeEach(inject((_$compile_, _$rootScope_) ->
        $compile = _$compile_
        $rootScope = _$rootScope_

        refreshCalledCounter = 0
        lastCallbackResult = null
        $rootScope.t = (x) -> x
        $rootScope.translate = (x) -> x
        $rootScope.okCallback = okCallback
    ))


    it "Test generic choice popover", ->
        template = """
        <div>
            <a href=""
                gm-generic-choice-popover="okCallback(1, selectedId)"
                gm-popover-class-name="status-popover"
                gm-popover-title="issues.select-status-popover"
                gm-popover-model="elements"
                gm-popover-no-body="true">FooBar</a>
        </div>
        """

        element = $compile(template)($rootScope)

        $rootScope.elements = [{id: 1, name: "foo"}, {id: 2, name: "bar"}]
        $rootScope.$digest()

        element.find("a").click()
        expect(element.find(".btn-accept")).to.be.lengthOf(2)

        element.find(".btn-accept:first").click()
        expect(lastCallbackResult).to.be.equal(1)

    it "Test Markdown preview popover", ->
        template = """
        <div>
        <span data-icon="o" class="icon blocked"
            gm-wiki-preview-popover=""
            gm-popover-model="note"
            gm-popover-title="issues.select-status-popover"
            gm-popover-class-name="issue-blocked-popover"
            gm-popover-no-body="true">
        </span>
        </div>
        """

        element = $compile(template)($rootScope)

        $rootScope.note = "<b>foo</b>"
        $rootScope.$digest()

        element.find("span.blocked").click()
        expect(element.find(".btn-accept")).to.be.lengthOf(1)

    it "Test user choice popover", ->
        template = """
        <div>
            <a href=""
                gm-user-choice-popover="okCallback(1, selectedId)"
                gm-popover-class-name="developers-popover"
                gm-popover-title="issues.select-user-popover"
                gm-popover-model="members"
                gm-popover-model-transformer="membersToChoicesTransformer"
                gm-popover-no-body="true"
                gm-popover-empty-item="issues.unassigned-popover"></a>
        </div>
        """

        element = $compile(template)($rootScope)

        $rootScope.members = [{user: 1, full_name: "foo"}, {user: 2, full_name: "bar"}]
        $rootScope.$digest()

        element.find("a").click()
        expect(element.find(".btn-accept")).to.be.lengthOf(3)

        element.find(".btn-accept:first").click()
        expect(lastCallbackResult).to.be.equal("")

    it "Test template popover", ->
        template = """
        <div>
            <a data-icon="l" class="btn-small-preview option"
                gm-template-popover="foobar"
                gm-popover-no-body="true"
                gm-popover-model="data">
            </a>

            <script type="text/ng-template" id="foobar">
                <div class="test-class">foobar</div>
            </script>
        </div>
        """

        element = $compile(template)($rootScope)

        $rootScope.data = {}
        $rootScope.$digest()

        element.find("a").click()
        expect(element.find(".test-class")).to.be.lengthOf(1)

    it "Test dialog popover", ->
        template = """
        <div>
            <a data-icon="h" class="btn-small-remove option"
                gm-generic-dialog-popover="okCallback(1)"
                gm-popover-model="issue"
                gm-popover-no-body="true"
                gm-popover-title-bind="'issues.issue-delete-sure'|i18next:{subject: issue.subject}">
                <span class="help-box" i18next="issues.remove">Remove</span>
            </a>
        </div>
        """
        element = $compile(template)($rootScope)

        $rootScope.issue = {
            subject: "Test"
        }
        $rootScope.$digest()

        element.find("a").click()
        expect(element.find(".btn-accept")).to.be.lengthOf(1)
        expect(element.find(".btn-cancel")).to.be.lengthOf(1)


        element.find(".btn-cancel").click()
        expect(element.find(".btn-accept")).to.be.lengthOf(0)
        expect(element.find(".btn-cancel")).to.be.lengthOf(0)

    # it "Test popover destroy scope", ->
    #     template = """
    #     <div>
    #         <a data-icon="h" class="btn-small-remove option"
    #             gm-generic-dialog-popover="okCallback(1)"
    #             gm-popover-model="issue"
    #             gm-popover-no-body="true"
    #             gm-popover-title-bind="'issues.issue-delete-sure'|i18next:{subject: issue.subject}">
    #             <span class="help-box" i18next="issues.remove">Remove</span>
    #         </a>
    #     </div>
    #     """

    #     scope = $rootScope.$new()
    #     element = $compile(template)(scope)

    #     $rootScope.issue = {
    #         subject: "Test"
    #     }
    #     $rootScope.$digest()

    #     element.trigger("$destroy")
    #     element.find("a").click()
    #     expect(element.find(".btn-accept")).to.be.lengthOf(0)

