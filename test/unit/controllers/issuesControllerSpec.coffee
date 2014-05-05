describe "issuesController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.issues"))

    describe "IssuesViewController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            scope = $rootScope.$new()
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            routeParams = {
                pslug: "test"
                ref: "1"
            }
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve()
                    return defered.promise
            }
            ctrl = $controller("IssuesViewController", {
                $scope: scope
                $routeParams: routeParams
                $confirm: confirmMock
                $modal: modalMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?issue=1&project=test").respond(200, {
                project: 1,
                issue: 1
            })
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, {
                id: 1,
                domain: 1,
                name: "Project Example 0",
                slug: "project-example-0",
                description: "Project example 0 description",
                created_date: "2013-12-20T09:53:46.361Z",
                modified_date: "2013-12-20T09:53:59.027Z",
                owner: 2,
                public: true,
                total_milestones: 5,
                total_story_points: 1062.0,
                default_points: 1,
                default_us_status: 1,
                default_task_status: 1,
                default_priority: 2,
                default_severity: 3,
                default_issue_status: 1,
                default_issue_type: 1,
                default_question_status: 1,
                members: []
                tags: "",
                list_of_milestones: [],
                roles: [],
                active_memberships: [],
                memberships: [],
                us_statuses: [],
                points: [],
                task_statuses: [
                    {
                        id: 1,
                        name: "New",
                        order: 1,
                        is_closed: false,
                        project: 1
                    },
                    {
                        id: 2,
                        name: "In progress",
                        order: 2,
                        is_closed: false,
                        color: "#ff9900",
                        project: 1
                    },
                    {
                        id: 3,
                        name: "Ready for test",
                        order: 3,
                        is_closed: true,
                        color: "#ffcc00",
                        project: 1
                    },
                    {
                        id: 4,
                        name: "Closed",
                        order: 4,
                        is_closed: true,
                        color: "#669900",
                        project: 1
                    },
                    {
                        id: 5,
                        name: "Needs Info",
                        order: 5,
                        is_closed: false,
                        color: "#999999",
                        project: 1
                    }
                ],
                priorities: [],
                severities: [],
                issue_statuses: [],
                issue_types: [],
            })
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, [
                id: 1,
                is_active: true,
                username: "admin",
                email: "admin@taiga.io",
                first_name: "Test",
                last_name: "Administrator",
                full_name: "Test Administrator",
                color: "black",
                photo: "",
                default_language: "",
                default_timezone: "",
                description: "",
                notify_changes_by_me: false,
                notify_level: "no_events"
            ])
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, [
                computable: false,
                id: 47,
                name: "Product Owner",
                order: 50,
                permissions: [],
                project: 1
            ])
            httpBackend.whenGET("#{APIURL}/issues/1?project=1").respond(200, {
                id: 1,
                ref: 1,
                project: 1,
                milestone: 54,
                milestone_slug: "sprint-6-1",
                user_story: 255,
                subject: "Añadir el sistema de plantillas en el back",
                owner: 1,
                created_date: "2014-02-28T13:55:21.802Z",
                modified_date: "2014-02-28T13:56:20.593Z",
                finished_date: null,
                status: 1,
                is_blocked: false,
                blocked_note: "",
                assigned_to: 1,
                comment: "",
                description: "",
                is_iocaine: false,
                tags: "",
                watchers: []
            })
            httpBackend.whenGET("#{APIURL}/projects/1/tags").respond(200, ["tag1", "tag2", "tag3"])
            httpBackend.whenGET("#{APIURL}/issues/1?order_by=status&project=1").respond(200)
            httpBackend.whenGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200)
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section issues", ->
            expect(ctrl.section).to.be.equal("issues")

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it "should allow to save a new attachment", inject ($q) ->
            ctrl.rs.uploadIssueAttachment = (projectId, issueId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            ctrl.scope.projectId = 1
            ctrl.scope.issueId = 1
            ctrl.scope.newAttachments = []
            result = ctrl.saveNewAttachments()
            expect(result).to.be.null

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.issueId = 1
            ctrl.scope.newAttachments = ["good", "good", "good"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it "should allow to save a new attachment (taking care on errors)", inject ($q) ->
            sinon.spy(ctrl.gmFlash, "error")

            ctrl.rs.uploadIssueAttachment = (projectId, issueId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.issueId = 1
            ctrl.scope.newAttachments = ["bad", "bad", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledOnce

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.issueId = 1
            ctrl.scope.newAttachments = ["good", "good", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledTwice

        it 'should allow to delete a issue attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('issues/attachments', {"id": "test", "content": "test"})]
            httpBackend.expectDELETE("#{APIURL}/issues/attachments/test").respond(200)
            promise = ctrl.removeAttachment(ctrl.scope.attachments[0])
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.attachments).to.be.deep.equal([])

        it 'should allow to delete a not uploaded attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('issues/attachments', {"id": "test", "content": "test"})]
            ctrl.removeNewAttachment(ctrl.scope.attachments[0])
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it 'should allow open the generate user story form', inject ($model) ->
            ctrl.scope.constants.computableRolesList = [{id: 1}, {id: 2}]
            ctrl.openCreateUserStoryForm()
            httpBackend.flush()

            ctrl.scope.issue = null
            ctrl.openCreateUserStoryForm()
            httpBackend.flush()

        it 'should allow submit the issue form', inject ($model) ->
            ctrl.scope.form = {}
            ctrl.scope.issue = $model.make_model('issues', {id: 1, ref: "1", description: "test"})
            httpBackend.expectPATCH("#{APIURL}/issues/1", {description: "test2"}).respond(200)
            ctrl.scope.form.description = "test2"
            ctrl._submit()
            httpBackend.flush()

    describe "IssuesController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            routeParams = {
                pslug: "test"
                ref: "1"
            }
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve()
                    return defered.promise
            }
            gmFiltersMock = {
                generateTagsFromUserStoriesList: ->
                    ["test1", "test2", "test3"]
                generateFiltersForIssues: ->
                    ["test1", "test2", "test3"]
                getSelectedFiltersList: ->
                    ["test2"]
                isFilterSelected: ->
                    true
                selectFilter: ->
                unselectFilter: ->
                plainTagsToObjectTags: $gmFilters.plainTagsToObjectTags
                filterToText: $gmFilters.filterToText
                makeIssuesQueryParams: ->
            }
            ctrl = $controller("IssuesController", {
                $scope: scope
                $routeParams: routeParams
                $modal: modalMock
                $gmFilters: gmFiltersMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test").respond(200, {project: 1})
            httpBackend.whenGET("#{APIURL}/projects/1?").respond(200, {
                id: 1,
                members: []
                tags: "",
                list_of_milestones: [],
                roles: [],
                active_memberships: [],
                memberships: [],
                us_statuses: [],
                points: [],
                task_statuses: [],
                priorities: [],
                severities: [],
                issue_statuses: [],
                issue_types: [],
            })
            httpBackend.whenGET("#{APIURL}/users?project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/roles?project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/issues/?project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/projects/1/issue_filters_data").respond(200, [])
            httpBackend.whenGET("#{APIURL}/projects/1/issues_stats").respond(200, [])
            httpBackend.whenGET("#{APIURL}/issues?order_by=-severity&page=1&project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/issues?project=1").respond(200, [])

            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section issues", ->
            expect(ctrl.section).to.be.equal("issues")

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to refresh issues', ->
            httpBackend.expectGET("#{APIURL}/projects/1/issues_stats").respond(200, [])
            httpBackend.expectGET("#{APIURL}/issues?project=1").respond(200, [])
            promise = ctrl.refreshIssues()
            httpBackend.flush()
            promise.should.be.fulfilled

        it 'should allow to refresh filters', ->
            httpBackend.expectGET("#{APIURL}/projects/1/issue_filters_data").respond(200, [])
            promise = ctrl.refreshFilters()
            httpBackend.flush()
            promise.should.be.fulfilled

        it 'should allow to refresh all', ->
            httpBackend.expectGET("#{APIURL}/projects/1/issue_filters_data").respond(200, [])
            httpBackend.expectGET("#{APIURL}/projects/1/issues_stats").respond(200, [])
            httpBackend.expectGET("#{APIURL}/issues?project=1").respond(200, [])

            promise = ctrl.refreshAll()
            expect(ctrl.scope.refreshing).to.be.true
            httpBackend.flush()

            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.refreshing).to.be.false

        it "should allow to check if a filter is selected", ->
            expect(ctrl.isFilterSelected("test")).to.be.true

        it "should allow toggle a filter", ->
            ctrl.refreshIssues = ->

            sinon.spy(ctrl.gmFilters, "selectFilter")
            sinon.spy(ctrl.gmFilters, "unselectFilter")
            sinon.spy(ctrl, "refreshIssues")

            ctrl.selectedFilters = [{type: "test1", id: "test1"}, {type:"test2", id: "test2"}]

            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.selectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([{type: "test1", id: "test1"}, {type:"test2", id: "test2"}, {type: "test", id: "test"}])

            ctrl.selectedFilters = [{type: "test1", id: "test1"}, {type:"test2", id: "test2"}, {type: "test", id: "test"}]
            ctrl.toggleFilter({type: "test", id: "test"})
            expect(ctrl.gmFilters.unselectFilter).have.been.called.once
            expect(ctrl.selectedFilters).to.be.deep.equal([{type: "test1", id: "test1"}, {type:"test2", id: "test2"}])

            expect(ctrl.refreshIssues).have.been.called.twice

        it "should allow initialize the filters", ->
            ctrl.initializeSelectedFilters()
            expect(ctrl.selectedFilters).to.be.deep.equal(["test2"])

        it "should allow load issues", ->
            sinon.spy(ctrl.scope, "$emit")
            httpBackend.expectGET("#{APIURL}/issues?project=1").respond(
                200,
                [{test: "test"}],
                {
                    "x-pagination-count": 5
                    "x-pagination-current": 2
                    "x-paginated-by": 10
                }
            )
            promise = ctrl.loadIssues()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(_.map(ctrl.scope.issues, (issue) -> issue.getAttrs())).to.be.deep.equal([{test: "test"}])
                expect(ctrl.scope.count).to.be.equal(5)
                expect(ctrl.scope.paginatedBy).to.be.equal(10)
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice

        it "should allow load issues filters data", ->
            httpBackend.expectGET("#{APIURL}/projects/1/issue_filters_data").respond(200, [])
            promise = ctrl.loadIssuesFiltersData()
            httpBackend.flush()
            promise.should.be.fulfilled

        it "should allow load stats", ->
            httpBackend.expectGET("#{APIURL}/projects/1/issues_stats").respond(200, [])
            promise = ctrl.loadStats()
            httpBackend.flush()
            promise.should.be.fulfilled

        it "should allow to open create issue form", ->
            ctrl.refreshIssues = ->
            ctrl.scope.projectId = 1

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "refreshIssues")

            promise = ctrl.openCreateIssueForm()

            expect(ctrl.modal.open).have.been.calledWith("issue-form", {type: "create"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).have.been.called.once

        it "should allow to open edit issue form", ->
            ctrl.refreshIssues = ->
            ctrl.scope.projectId = 1

            sinon.spy(ctrl.modal, "open")
            sinon.spy(ctrl, "refreshIssues")

            promise = ctrl.openEditIssueForm({test: "test"})

            expect(ctrl.modal.open).have.been.calledWith("issue-form", {issue: {test: "test"}, type: "edit"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).have.been.called.once

        it "should allow to toggle show graphs", ->
            ctrl.scope.showGraphs = false
            ctrl._toggleShowGraphs()
            expect(ctrl.scope.showGraphs).to.be.true
            ctrl._toggleShowGraphs()
            expect(ctrl.scope.showGraphs).to.be.false

        it "should allow to update issue assignation", inject ($model) ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            issue = $model.make_model("issues", {id: 1, assigned_to: 1})

            httpBackend.expectPATCH("#{APIURL}/issues/1", {assigned_to: 10}).respond(200)
            promise = ctrl.updateIssueAssignation(issue, 10)

            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).not.called

            httpBackend.expectPATCH("#{APIURL}/issues/1", {assigned_to: null}).respond(200)
            promise = ctrl.updateIssueAssignation(issue)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).not.called

        it "should allow to update issue status", inject ($model) ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            issue = $model.make_model("issues", {id: 1, status: 1})

            httpBackend.expectPATCH("#{APIURL}/issues/1", {status: 10}).respond(200)
            promise = ctrl.updateIssueStatus(issue, 10)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).not.called

        it "should allow to update issue severity", inject ($model) ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            issue = $model.make_model("issues", {id: 1, severity: 1})

            httpBackend.expectPATCH("#{APIURL}/issues/1", {severity: 10}).respond(200)
            promise = ctrl.updateIssueSeverity(issue, 10)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).not.called

        it "should allow to update issue priority", inject ($model) ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            issue = $model.make_model("issues", {id: 1, priority: 1})

            httpBackend.expectPATCH("#{APIURL}/issues/1", {priority: 10}).respond(200)
            promise = ctrl.updateIssuePriority(issue, 10)
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.refreshIssues).not.called

        it "should allow to remove a issue", inject ($model) ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            ctrl.scope.issues = _.map([{id: 1, order: 2}, {id: 2, order: 1}, {id: 3, order: 3}], (us) -> $model.make_model("issues", us))
            issue = ctrl.scope.issues[0]

            httpBackend.expectDELETE("#{APIURL}/issues/1").respond(200)

            promise = ctrl.removeIssue(issue)
            httpBackend.flush()

            promise.should.be.fulfilled. then ->
                expect(ctrl.scope.issues).to.have.length(2)
                expect(ctrl.refreshIssues).have.been.called.once

        it "should allow to open a issue", ->
            sinon.spy(ctrl.location, "url")
            ctrl.openIssue("test", 1)
            expect(ctrl.location.url).have.been.calledWith("/project/test/issues/1")

        it "should allow to change to an other page", ->
            ctrl.refreshIssues = ->
            sinon.spy(ctrl, "refreshIssues")

            expect(ctrl.scope.page).to.be.equal(1)

            ctrl.scope.setPage(6)

            expect(ctrl.scope.page).to.be.equal(6)
            expect(ctrl.refreshIssues).have.been.called.once


    describe "IssuesModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("IssuesModalController", {
                $scope: scope
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("#{APIURL}/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to load project tags", ->
            ctrl.scope.projectId = 1
            httpBackend.expectGET("http://localhost:8000/api/v1/projects/1/tags").respond(200, "test")
            promise = ctrl.loadProjectTags()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.projectTags).to.be.equal("test")

        it "should allow to get the tags list", ->
            ctrl.projectTags = undefined
            expect(ctrl.getTagsList()).to.be.deep.equal([])
            ctrl.projectTags = ["test"]
            expect(ctrl.getTagsList()).to.be.deep.equal(["test"])

        it "should allow to open the modal", inject ($q) ->
            ctrl.loadProjectTags = ->
            ctrl.loadAttachments = ->
            sinon.spy(ctrl, "loadProjectTags")
            sinon.spy(ctrl, "loadAttachments")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.scope.context = {issue: {id:1}}
            ctrl.scope.project = {
                default_issue_status: 1
                default_issue_type: 2
                default_priority: 3
                default_severity: 4
            }

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.form).to.be.deep.equal({id:1})
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.calledWith("wiki:clean-previews")
            expect(ctrl.scope.$broadcast).have.been.called.twice
            expect(ctrl.loadProjectTags).have.been.called.once
            expect(ctrl.loadAttachments).have.been.called.once

        it "should allow to open the modal without issue", inject ($q) ->
            ctrl.loadProjectTags = ->
            ctrl.loadAttachments = ->
            sinon.spy(ctrl, "loadProjectTags")
            sinon.spy(ctrl, "loadAttachments")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.scope.context = {issue: null}
            ctrl.scope.project = {
                default_issue_status: 1
                default_issue_type: 2
                default_priority: 3
                default_severity: 4
            }

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.form).to.be.deep.equal({status: 1, type: 2, priority: 3, severity: 4})
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.calledWith("wiki:clean-previews")
            expect(ctrl.scope.$broadcast).have.been.called.twice
            expect(ctrl.loadProjectTags).have.been.called.once
            expect(ctrl.loadAttachments).have.not.been.called

        it "should allow to save the form of the modal", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/issues", {test: "test"}).respond(200, {id: 1, test: "test"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal with attachments", inject ($model, $q) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            ctrl.saveNewAttachments = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            ctrl.scope.newAttachments = ["test", "test"]

            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")
            sinon.spy(ctrl, "saveNewAttachments")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/issues", {test: "test"}).respond(200, {id: 1, test: "test"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once
                expect(ctrl.saveNewAttachments).have.been.called.twice

        it "should allow to save the form of the modal (on edit)", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = $model.make_model("issues", {id: 3, test: "test"})
            ctrl.scope.form.test = "test1"

            httpBackend.expectPUT("http://localhost:8000/api/v1/issues/3", {id: 3, test: "test1"}).respond(200, {id: 1, test: "test1"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal (on error)", ->
            sinon.spy(ctrl.scope, "$emit")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/issues", {test: "test"}).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.formOpened).to.be.true
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({test: "test"})

        it "should allow to save a new attachment", inject ($q) ->
            ctrl.rs.uploadIssueAttachment = (projectId, issueId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            ctrl.scope.newAttachments = []
            result = ctrl.saveNewAttachments(1, 1)
            expect(result).to.be.null

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200, [])
            ctrl.scope.newAttachments = ["good", "good", "good"]
            promise = ctrl.saveNewAttachments(1, 1)
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it "should allow to save a new attachment (taking care on errors)", inject ($q) ->
            sinon.spy(ctrl.gmFlash, "error")

            ctrl.rs.uploadIssueAttachment = (projectId, issueId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200, [])
            ctrl.scope.newAttachments = ["bad", "bad", "bad"]
            promise = ctrl.saveNewAttachments(1, 1)
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledOnce

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200, [])
            ctrl.scope.newAttachments = ["good", "good", "bad"]
            promise = ctrl.saveNewAttachments(1, 1)
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledTwice

        it 'should allow to delete a issue attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('issues/attachments', {"id": "test", "content": "test"})]
            httpBackend.expectDELETE("#{APIURL}/issues/attachments/test").respond(200)
            promise = ctrl.removeAttachment(ctrl.scope.attachments[0])
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.attachments).to.be.deep.equal([])

        it 'should allow to delete a not uploaded attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('issues/attachments', {"id": "test", "content": "test"})]
            ctrl.removeNewAttachment(ctrl.scope.attachments[0])
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

    describe "IssueUserStoryModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("IssueUserStoryModalController", {
                $scope: scope
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET("#{APIURL}/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to load project tags", ->
            ctrl.scope.projectId = 1
            httpBackend.expectGET("http://localhost:8000/api/v1/projects/1/tags").respond(200, "test")
            promise = ctrl.loadProjectTags()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.projectTags).to.be.equal("test")

        it "should allow to get the tags list", ->
            ctrl.projectTags = undefined
            expect(ctrl.getTagsList()).to.be.deep.equal([])
            ctrl.projectTags = ["test"]
            expect(ctrl.getTagsList()).to.be.deep.equal(["test"])

        it "should allow to open the modal", inject ($q) ->
            ctrl.loadProjectTags = ->
            sinon.spy(ctrl, "loadProjectTags")
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.scope.context = {us: {id:1, points: {1: 1, 2: 2}}}

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.form).to.be.deep.equal({id: 1, points: {1: 1, 2: 2}})
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.calledWith("wiki:clean-previews")
            expect(ctrl.scope.$broadcast).have.been.called.twice
            expect(ctrl.loadProjectTags).have.been.called.once

        it "should allow to save the form of the modal", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/userstories?",
                {test: "test"}
            ).respond(200, {id: 1, test: "test"})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.gmFlash.info).have.been.called.once
                expect(ctrl.gmOverlay.close).have.been.called.once
                expect(ctrl.scope.defered.resolve).have.been.called.once

        it "should allow to save the form of the modal (on error)", ->
            sinon.spy(ctrl.scope, "$emit")

            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST(
                "http://localhost:8000/api/v1/userstories?",
                {test: "test"}
            ).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.formOpened).to.be.true
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({test: "test"})
