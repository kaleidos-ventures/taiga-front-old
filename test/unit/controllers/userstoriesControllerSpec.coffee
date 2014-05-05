describe "userstoriesController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.user-story"))

    describe "UserStoryViewController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q) ->
            scope = $rootScope.$new()
            routeParams = {
                pslug: "test"
                ref: "1"
            }
            confirmMock = {
                confirm: (text) ->
                    defered = $q.defer()
                    defered.resolve("test")
                    return defered.promise
            }
            ctrl = $controller("UserStoryViewController", {
                $scope: scope
                $routeParams: routeParams
                $confirm: confirmMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?project=test&us=1").respond(200, {
                project: 1,
                us: 1
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
            httpBackend.whenGET("#{APIURL}/userstories/1?project=1").respond(200, {
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
            httpBackend.whenGET("#{APIURL}/userstories/attachments?object_id=1&project=1").respond(200, [
                id: 1,
                object_id: 1,
                project: 1,
                name: "test.txt",
                created_date: "2014-03-28T09:44:27.419Z",
                modified_date: "2014-03-28T09:44:27.419Z"
                attached_file: "attachment-files/taiga/us/1395999867/test.txt"
                url: "http://localhost:8000/media/attachment-files/taiga/us/1395999867/test.txt"
                size: 11992,
                owner: 9,
            ])
            httpBackend.whenGET("#{APIURL}/projects/1/tags").respond(200, ["tag1", "tag2", "tag3"])
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section userstories", ->
            expect(ctrl.section).to.be.equal("user-stories")

        it "should allow to save a new attachment", inject ($q) ->
            ctrl.rs.uploadUserStoryAttachment = (projectId, usId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            ctrl.scope.projectId = 1
            ctrl.scope.usId = 1
            ctrl.scope.newAttachments = []
            result = ctrl.saveNewAttachments()
            expect(result).to.be.null

            httpBackend.expectGET("#{APIURL}/userstories/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.usId = 1
            ctrl.scope.newAttachments = ["good", "good", "good"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.fulfilled
            promise.then ->
                expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it "should allow to save a new attachment (taking care on errors)", inject ($q) ->
            sinon.spy(ctrl.gmFlash, "error")

            ctrl.rs.uploadUserStoryAttachment = (projectId, usId, attachment) ->
                defered = $q.defer()
                if attachment == "good"
                    defered.resolve("good")
                else if attachment == "bad"
                    defered.reject("bad")
                return defered.promise

            httpBackend.expectGET("#{APIURL}/userstories/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.usId = 1
            ctrl.scope.newAttachments = ["bad", "bad", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledOnce

            httpBackend.expectGET("#{APIURL}/userstories/attachments?object_id=1&project=1").respond(200)
            ctrl.scope.projectId = 1
            ctrl.scope.usId = 1
            ctrl.scope.newAttachments = ["good", "good", "bad"]
            promise = ctrl.saveNewAttachments()
            httpBackend.flush()
            promise.should.have.been.rejected
            ctrl.gmFlash.error.should.have.been.calledTwice

        it 'should allow to delete a us attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('userstories/attachments', {"id": "test", "content": "test"})]
            httpBackend.expectDELETE("#{APIURL}/userstories/attachments/test").respond(200)
            promise = ctrl.removeAttachment(ctrl.scope.attachments[0])
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.attachments).to.be.deep.equal([])

        it 'should allow to delete a not uploaded attachment', inject ($model) ->
            ctrl.scope.attachments = [$model.make_model('userstories/attachments', {"id": "test", "content": "test"})]
            ctrl.removeNewAttachment(ctrl.scope.attachments[0])
            expect(ctrl.scope.newAttachments).to.be.deep.equal([])

        it 'should allow submit the user story form', inject ($model) ->
            ctrl.scope.form = {}
            ctrl.scope.issue = $model.make_model('userstories', {id: 1, ref: "1", description: "test"})
            httpBackend.expectPATCH("#{APIURL}/userstories/1", {description: "test2"}).respond(200)
            ctrl.scope.form.description = "test2"
            ctrl._submit()
            httpBackend.flush()
