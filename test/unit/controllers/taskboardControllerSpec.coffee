describe "taskboardController", ->
    APIURL = "http://localhost:8000/api/v1"

    beforeEach(module("taiga"))
    beforeEach(module("taiga.controllers.taskboard"))

    describe "TaskboardController", ->
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
                sslug: "test"
            }
            modalMock = {
                open: ->
                    defered = $q.defer()
                    defered.resolve({test: "test"})
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
            ctrl = $controller("TaskboardController", {
                $scope: scope
                $routeParams: routeParams
                $modal: modalMock
                $gmFilters: gmFiltersMock
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.whenGET("#{APIURL}/resolver?milestone=test&project=test").respond(200, {project: 1, milestone: 2})
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
            httpBackend.whenGET("#{APIURL}/tasks?milestone=2&project=1").respond(200, [])
            httpBackend.whenGET("#{APIURL}/milestones/2?project=1").respond(200, {user_stories: []})
            httpBackend.whenGET("#{APIURL}/milestones/2/stats").respond(200, [])

            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should have section issues", ->
            expect(ctrl.section).to.be.equal("dashboard")

        it 'should have a title', ->
            expect(ctrl.getTitle).to.be.ok

        it 'should allow to load tasks', ->
            ctrl.formatUserStoryTasks = ->
            ctrl.calculateStats = ->
            sinon.spy(ctrl, "formatUserStoryTasks")
            sinon.spy(ctrl, "calculateStats")

            httpBackend.expectGET("#{APIURL}/tasks?milestone=2&project=1").respond(200, [{test: "test"}])
            promise = ctrl.loadTasks()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(_.map(ctrl.scope.tasks, (task) -> task.getAttrs())).to.be.deep.equal([{test: "test"}])
                expect(ctrl.formatUserStoryTasks).have.been.called.once
                expect(ctrl.calculateStats).have.been.called.once

        it "should allow to open create task form", ->
            ctrl.formatUserStoryTasks = ->
            ctrl.calculateStats = ->
            ctrl.scope.project = {
                default_task_status: 1
            }
            sinon.spy(ctrl, "formatUserStoryTasks")
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.modal, "open")

            promise = ctrl.openCreateTaskForm({id: 1})

            expect(ctrl.modal.open).have.been.calledWith(
                "task-form",
                {
                    task: {
                        milestone: 2,
                        project: 1,
                        status: 1,
                        user_story: 1
                    }
                    type: "create"
                }
            )

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStoryTasks).have.been.called.once
                expect(ctrl.calculateStats).have.been.called.once
                expect(_.map(ctrl.scope.tasks, (task) -> task.getAttrs())).to.be.deep.equal([{test: "test"}])

        it "should allow to open create task form without user story", ->
            ctrl.formatUserStoryTasks = ->
            ctrl.calculateStats = ->
            ctrl.scope.project = {
                default_task_status: 1
            }
            sinon.spy(ctrl, "formatUserStoryTasks")
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.modal, "open")

            promise = ctrl.openCreateTaskForm()

            expect(ctrl.modal.open).have.been.calledWith(
                "task-form",
                {
                    task: {
                        milestone: 2,
                        project: 1,
                        status: 1,
                    }
                    type: "create"
                }
            )

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStoryTasks).have.been.called.once
                expect(ctrl.calculateStats).have.been.called.once
                expect(_.map(ctrl.scope.tasks, (task) -> task.getAttrs())).to.be.deep.equal([{test: "test"}])

        it "should allow to open edit task form", ->
            ctrl.formatUserStoryTasks = ->
            ctrl.calculateStats = ->

            sinon.spy(ctrl, "formatUserStoryTasks")
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.modal, "open")

            promise = ctrl.openEditTaskForm({test: "test1"}, {test: "test2"})

            expect(ctrl.modal.open).have.been.calledWith("task-form", {task: {test: "test2"}, type: "edit"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStoryTasks).have.been.called.once
                expect(ctrl.calculateStats).have.been.called.once

        it "should allow to format user story tasks", ->
            ctrl.scope.userstoriesList = [{id: 1}, {id: 2}]
            ctrl.scope.constants = {
                taskStatusesList: [{id: 1}, {id: 2}]
            }
            ctrl.scope.tasks = [
                {id: 1, user_story: 1, status: 1}
                {id: 2, user_story: 2, status: 2}
                {id: 3, user_story: null, status: 1}
                {id: 4, user_story: null, status: 2}
                {id: 5, user_story: null, status: null}
                {id: 5, user_story: 1, status: null}
                {id: 5, user_story: 8, status: null}
            ]

            ctrl.formatUserStoryTasks()
            expect(ctrl.scope.usTasks).to.be.deep.equal({
                1: {
                    1: [{id: 1, user_story: 1, status: 1}]
                    2: []
                }
                2: {
                    1: []
                    2: [{id: 2, user_story: 2, status: 2}]
                }
            })
            expect(ctrl.scope.unassignedTasks).to.be.deep.equal({
                1: [{id: 3, user_story: null, status: 1}]
                2: [{id: 4, user_story: null, status: 2}]
            })

        it "should allow to calculate stats", ->
            httpBackend.expectGET("#{APIURL}/milestones/2/stats").respond(200, {
                total_points: [10, 20, 30]
                completed_points: [10, 20]
                total_userstories: 3
                completed_userstories: 2
                total_tasks: 15
                completed_tasks: 8
                iocaine_doses: 2
            })
            promise = ctrl.calculateStats()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.stats).to.be.deep.equal({
                    totalPoints: 60
                    completedPoints: 30
                    remainingPoints: 30
                    percentageCompletedPoints: "50.0"
                    totalUss: 3
                    compledUss: 2
                    remainingUss: 1
                    totalTasks: 15
                    completedTasks: 8
                    remainingTasks: 7
                    iocaineDoses: 2
                })

            httpBackend.expectGET("#{APIURL}/milestones/2/stats").respond(200, {
                total_points: []
                completed_points: []
                total_userstories: 0
                completed_userstories: 0
                total_tasks: 0
                completed_tasks: 0
                iocaine_doses: 0
            })
            promise = ctrl.calculateStats()
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.stats).to.be.deep.equal({
                    totalPoints: 0
                    completedPoints: 0
                    remainingPoints: 0
                    percentageCompletedPoints: 0
                    totalUss: 0
                    compledUss: 0
                    remainingUss: 0
                    totalTasks: 0
                    completedTasks: 0
                    remainingTasks: 0
                    iocaineDoses: 0
                })

        it "should allow to save user story points", inject ($model) ->
            ctrl.calculateStats = ->
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.scope, "$broadcast")
            us = $model.make_model("userstories", {id: 1, points: {}})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {points: {1: 5}}).respond(200)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.points[1]).to.be.equal(5)
                expect(us._moving).to.be.false
                expect(ctrl.calculateStats).have.been.called.once
                expect(ctrl.scope.$broadcast).have.been.calledWith("points:changed")

        it "should allow to save user story points (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, points: {}})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {points: {1: 5}}).respond(400)
            promise = ctrl.saveUsPoints(us, {id: 1}, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once
                expect(us.points).to.be.deep.equal({})

        it "should allow to save user story status", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {status: 5}).respond(200)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(us.status).to.be.equal(5)
                expect(us._moving).to.be.false

        it "should allow to save user story status (on error)", inject ($model) ->
            us = $model.make_model("userstories", {id: 1, status: 1})
            sinon.spy(us, "revert")

            httpBackend.expectPATCH("http://localhost:8000/api/v1/userstories/1", {status: 5}).respond(400)
            promise = ctrl.saveUsStatus(us, 5)
            expect(us._moving).to.be.true
            httpBackend.flush()
            promise.then ->
                expect(us.status).to.be.equal(1)
                expect(us._moving).to.be.false
                expect(us.revert).have.been.called.once

        it "should allow to open bulk tasks form", inject ($q) ->
            ctrl.modal.open = ->
                defered = $q.defer()
                defered.resolve([{test: "test"}])
                return defered.promise

            ctrl.formatUserStoryTasks = ->
            ctrl.calculateStats = ->

            sinon.spy(ctrl, "formatUserStoryTasks")
            sinon.spy(ctrl, "calculateStats")
            sinon.spy(ctrl.modal, "open")

            promise = ctrl.openBulkTasksForm("test")

            expect(ctrl.modal.open).have.been.calledWith("bulk-tasks-form", {us: "test"})

            promise.should.be.fulfilled.then ->
                expect(ctrl.formatUserStoryTasks).have.been.called.once
                expect(ctrl.calculateStats).have.been.called.once
                expect(_.map(ctrl.scope.tasks, (task) -> task.getAttrs())).to.be.deep.equal([{test: "test"}])

        it "should allow to move tasks from one status to another in unassigned tasks", inject ($model) ->
            ctrl.scope.unassignedTasks = {1:
                _.map(
                    [{id: 1, status: 1, user_story: null}, {id: 2, status: 1, user_story: null}],
                    (task) -> $model.make_model("tasks", task)
                )
            }

            task = $model.make_model("tasks", {id: 3, status: 8, user_story: null})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/tasks/3", {status: 1}).respond(200)
            promise = ctrl.sortableOnAdd(task, 1, {status: {id: 1}})
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.scope.unassignedTasks[1], (task) -> task.getAttrs())
                ).to.be.deep.equal([
                    {id: 1, status: 1, user_story: null},
                    {id: 3, status: 1, user_story: null},
                    {id: 2, status: 1, user_story: null}
                ])

        it "should allow to move tasks from one status to another in user stories", inject ($model) ->
            ctrl.scope.usTasks = {1: {1:
                _.map(
                    [{id: 1, status: 1, user_story: 1}, {id: 2, status: 1, user_story: 1}],
                    (task) -> $model.make_model("tasks", task)
                )
            }}

            task = $model.make_model("tasks", {id: 3, status: 8, user_story: 1})

            httpBackend.expectPATCH("http://localhost:8000/api/v1/tasks/3", {status: 1}).respond(200)
            httpBackend.expectGET("http://localhost:8000/api/v1/userstories/1").respond(200)
            promise = ctrl.sortableOnAdd(task, 1, {status: {id: 1}, us: $model.make_model("userstories", {id: 1})})
            httpBackend.flush()
            promise.should.be.fulfilled.then ->
                expect(
                    _.map(ctrl.scope.usTasks[1][1], (task) -> task.getAttrs())
                ).to.be.deep.equal([
                    {id: 1, status: 1, user_story: 1},
                    {id: 3, status: 1, user_story: 1},
                    {id: 2, status: 1, user_story: 1}
                ])

        it "should allow to remove tasks", inject ($model) ->
            ctrl.scope.usTasks = {1: {1:
                _.map(
                    [{id: 1, status: 1, user_story: 1}, {id: 2, status: 1, user_story: 1}, {id: 3, status: 1, user_story: 1}],
                    (task) -> $model.make_model("tasks", task)
                )
            }}

            task = ctrl.scope.usTasks[1][1][0]

            ctrl.sortableOnRemove(task, {status: {id: 1}, us: $model.make_model("userstories", {id: 1})})
            expect(
                _.map(ctrl.scope.usTasks[1][1], (task) -> task.getAttrs())
            ).to.be.deep.equal([
                {id: 2, status: 1, user_story: 1},
                {id: 3, status: 1, user_story: 1}
            ])

            ctrl.scope.unassignedTasks = {1:
                _.map(
                    [{id: 1, status: 1, user_story: 1}, {id: 2, status: 1, user_story: 1}, {id: 3, status: 1, user_story: 1}],
                    (task) -> $model.make_model("tasks", task)
                )
            }
            task = ctrl.scope.unassignedTasks[1][0]
            ctrl.sortableOnRemove(task, {status: {id: 1}})
            expect(
                _.map(ctrl.scope.unassignedTasks[1], (task) -> task.getAttrs())
            ).to.be.deep.equal([
                {id: 2, status: 1, user_story: 1},
                {id: 3, status: 1, user_story: 1}
            ])

    describe "TaskboardTaskModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("TaskboardTaskModalController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
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

            ctrl.scope.context = {task: {id:1}}

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

            httpBackend.expectPOST("http://localhost:8000/api/v1/tasks?", {test: "test"}).respond(200, {id: 1, test: "test"})
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

        it "should allow to save the form of the modal (on edit)", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.form = $model.make_model("tasks", {id: 3, test: "test"})
            ctrl.scope.form.test = "test1"

            httpBackend.expectPUT("http://localhost:8000/api/v1/tasks/3", {id: 3, test: "test1"}).respond(200, {id: 3, test: "test1"})
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

            httpBackend.expectPOST("http://localhost:8000/api/v1/tasks?", {test: "test"}).respond(400)
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected
            promise.then ->
                expect(ctrl.scope.formOpened).to.be.true
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:start")
                expect(ctrl.scope.$emit).have.been.calledWith("spinner:stop")
                expect(ctrl.scope.$emit).have.been.called.twice
                expect(ctrl.scope.checksleyErrors).to.be.deep.equal({test: "test"})

    describe "TaskboardBulkTasksModalController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("TaskboardBulkTasksModalController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to open the modal", inject ($q) ->
            sinon.spy(ctrl.scope, "$broadcast")

            ctrl.gmOverlay.open = ->
                defered = $q.defer()
                defered.resolve()
                return defered.promise

            promise = ctrl.openModal()
            expect(ctrl.scope.formOpened).to.be.true
            expect(ctrl.scope.form).to.be.deep.equal({})
            promise.should.be.fulfilled.then ->
                expect(ctrl.scope.formOpened).to.be.false
            expect(ctrl.scope.$broadcast).have.been.calledWith("checksley:reset")
            expect(ctrl.scope.$broadcast).have.been.called.once

        it "should allow to save the form of the modal", inject ($model) ->
            ctrl.gmOverlay.close = ->
            ctrl.scope.defered = {}
            ctrl.scope.defered.resolve = ->
            sinon.spy(ctrl.scope, "$emit")
            sinon.spy(ctrl.scope.defered, "resolve")
            sinon.spy(ctrl.gmOverlay, "close")
            sinon.spy(ctrl.gmFlash, "info")
            sinon.spy(ctrl, "closeModal")

            ctrl.scope.context = {us: {id: 1}}
            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/tasks/bulk_create", {test: "test", usId: 1}).respond(200, [{id: 1, test: "test"}])
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
            ctrl.scope.context = {us: {id: 1}}
            ctrl.scope.form = {test: "test"}

            httpBackend.expectPOST("http://localhost:8000/api/v1/tasks/bulk_create", {test: "test", usId: 1}).respond(400, {})
            promise = ctrl._submit()
            httpBackend.flush()
            promise.should.be.rejected

    describe "TaskboardTaskController", ->
        httpBackend = null
        scope = null
        ctrl = null

        beforeEach(inject(($rootScope, $controller, $httpBackend, $q, $gmFilters) ->
            scope = $rootScope.$new()
            ctrl = $controller("TaskboardTaskController", {
                $scope: scope
            })
            httpBackend = $httpBackend
            httpBackend.whenGET(APIURL+"/sites").respond(200, {test: "test"})
            httpBackend.flush()
        ))

        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to update task assignation", inject ($model) ->
            task = $model.make_model("tasks", {id: 1, assigned_to: 1})

            httpBackend.expectPATCH("#{APIURL}/tasks/1", {assigned_to: 10}).respond(200)
            promise = ctrl.updateTaskAssignation(task, 10)
            httpBackend.flush()
            promise.should.be.fulfilled

            httpBackend.expectPATCH("#{APIURL}/tasks/1", {assigned_to: null}).respond(200)
            promise = ctrl.updateTaskAssignation(task)
            httpBackend.flush()
            promise.should.be.fulfilled

            httpBackend.expectPATCH("#{APIURL}/tasks/1", {assigned_to: 10}).respond(400)
            promise = ctrl.updateTaskAssignation(task, 10)
            httpBackend.flush()
            promise.should.be.rejected

        it "should allow to open a user story", ->
            sinon.spy(ctrl.location, "url")
            ctrl.openTask("test", 1)
            expect(ctrl.location.url).have.been.calledWith("/project/test/tasks/1")
