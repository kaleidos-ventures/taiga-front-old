describe "resourceService", ->
    APIURL = "http://localhost:8000/api/v1"

    httpBackend = null

    beforeEach(module("taiga"))
    beforeEach(module("taiga.services.resource"))

    beforeEach inject ($httpBackend) ->
        httpBackend = $httpBackend
        httpBackend.whenGET("#{APIURL}/sites").respond(200, {test: "test"})
        httpBackend.flush()

    describe "resource service", ->
        afterEach ->
            httpBackend.verifyNoOutstandingExpectation()
            httpBackend.verifyNoOutstandingRequest()

        it "should allow to register a user", inject (resource, $gmAuth) ->
            $gmAuth.unsetUser(null)
            $gmAuth.setToken(null)
            expect($gmAuth.getToken()).to.be.null
            expect($gmAuth.getUser()).to.be.null
            httpBackend.expectPOST("#{APIURL}/auth/register", {"test": "data"}).respond(200, {"auth_token": "test"})
            promise = resource.register({"test": "data"})
            promise.should.be.fullfilled
            httpBackend.flush()
            expect($gmAuth.getToken()).to.be.equal("test")
            expect($gmAuth.getUser().getAttrs()).to.be.deep.equal({"auth_token": "test"})

            httpBackend.expectPOST("#{APIURL}/auth/register", {"test": "bad-data"}).respond(400)
            promise = resource.register({"test": "bad-data"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to login with a username and password", inject (resource, $gmAuth) ->
            $gmAuth.unsetUser(null)
            $gmAuth.setToken(null)
            expect($gmAuth.getToken()).to.be.null
            expect($gmAuth.getUser()).to.be.null
            httpBackend.expectPOST(
                "#{APIURL}/auth",
                {"username": "test", "password": "test"}
            ).respond(200, {"auth_token": "test"})
            promise = resource.login("test", "test")
            promise.should.be.fullfilled
            httpBackend.flush()
            expect($gmAuth.getToken()).to.be.equal("test")
            expect($gmAuth.getUser().getAttrs()).to.be.deep.equal({"auth_token": "test"})

            httpBackend.expectPOST(
                "#{APIURL}/auth",
                {"username": "bad", "password": "bad"}
            ).respond(400)
            promise = resource.login("bad", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to recover password with your email", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/users/password_recovery",
                {"username": "test"}
            ).respond(200, {"auth_token": "test"})
            promise = resource.recovery("test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/users/password_recovery",
                {"username": "bad"}
            ).respond(400)
            promise = resource.recovery("bad")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to change password from a recovery token", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/users/change_password_from_recovery",
                {"password": "test", "token": "test"}
            ).respond(200)
            promise = resource.changePasswordFromRecovery("test", "test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/users/change_password_from_recovery",
                {"password": "bad", "token": "bad"}
            ).respond(400)
            promise = resource.changePasswordFromRecovery("bad", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to change password for the current user", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/users/change_password",
                {"password": "test"}
            ).respond(200)
            promise = resource.changePasswordForCurrentUser("test")
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/users/change_password",
                {"password": "bad"}
            ).respond(400)
            promise = resource.changePasswordForCurrentUser("bad")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to resolve us/task/issue/milestone references or project slug", inject (resource) ->
            httpBackend.expectGET(
                "#{APIURL}/resolver?issue=7&milestone=4&project=test&task=10&us=3"
            ).respond(200)
            promise = resource.resolve({pslug: "test", usref: 3, taskref: 10, issueref: 7, mlref: 4})
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET(
                "#{APIURL}/resolver?issue=7&milestone=4&project=bad&task=10&us=3"
            ).respond(400)
            promise = resource.resolve({pslug: "bad", usref: 3, taskref: 10, issueref: 7, mlref: 4})
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/resolver").respond(200)
            promise = resource.resolve({})
            promise.should.be.fullfilled
            httpBackend.flush()

        it "should allow to get the site info", inject (resource) ->
            promise = resource.getSite()
            httpBackend.expectGET("#{APIURL}/sites").respond(200)
            promise.should.fullfilled
            httpBackend.flush()

            promise = resource.getSite()
            httpBackend.expectGET("#{APIURL}/sites").respond(400)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the site members", inject (resource) ->
            promise = resource.getSiteMembers()
            httpBackend.expectGET("#{APIURL}/site-members").respond(200)
            promise.should.fullfilled
            httpBackend.flush()

            promise = resource.getSiteMembers()
            httpBackend.expectGET("#{APIURL}/site-members").respond(400)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a project", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/site-projects?template=kanban", {"test": "test"}).respond(200)
            promise = resource.createProject({"test": "test"}, "kanban")
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/site-projects?template=kanban", {"test": "bad"}).respond(400)
            promise = resource.createProject({"test": "bad"}, "kanban")
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the project list", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects").respond(200)
            promise = resource.getProjects()
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/projects").respond(400)
            promise = resource.getProjects()
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the list of permissions", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/permissions").respond(200, [
                {codename: "view_us"}
                {codename: "edit_us"}
                {codename: "view_task"}
                {codename: "edit_task"}
            ])
            promise = resource.getPermissions()
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/permissions").respond(400)
            promise = resource.getPermissions()
            httpBackend.flush()
            promise.should.be.rejected

        it "should allow to get a project", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects/1?").respond(200)
            promise = resource.getProject(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/projects/100?").respond(400)
            promise = resource.getProject(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a project stats", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects/1/stats").respond(200)
            promise = resource.getProjectStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/projects/100/stats").respond(400)
            promise = resource.getProjectStats(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a project issues stats", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects/1/issues_stats").respond(200)
            promise = resource.getIssuesStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/projects/100/issues_stats").respond(400)
            promise = resource.getIssuesStats(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a project tags", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects/1/tags").respond(200)
            promise = resource.getProjectTags(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/projects/100/tags").respond(400)
            promise = resource.getProjectTags(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a project issues filters data", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/projects/1/issue_filters_data").respond(200)
            promise = resource.getIssuesFiltersData(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/projects/100/issue_filters_data").respond(400)
            promise = resource.getIssuesFiltersData(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a membership", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/memberships?", {"test": "test"}).respond(200)
            promise = resource.createMembership({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/memberships?", {"test": "bad"}).respond(400)
            promise = resource.createMembership({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a project roles", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/roles?project=1").respond(200)
            promise = resource.getRoles(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/roles?project=100").respond(400)
            promise = resource.getRoles(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a role", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/roles?", {"test": "test", "project": 1}).respond(200)
            promise = resource.createRole(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/roles?", {"test": "bad", "project": 1}).respond(400)
            promise = resource.createRole(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get all the milestones of a project", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/milestones?project=1").respond(200, [{"user_stories": [{"test": "test"}]}])
            promise = resource.getMilestones(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/milestones?project=100").respond(400)
            promise = resource.getMilestones(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get one milestone", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/milestones/1?project=1").respond(200, {"user_stories": [{"test": "test"}]})
            promise = resource.getMilestone(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/milestones/100?project=1").respond(400)
            promise = resource.getMilestone(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a milestone stats", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/milestones/1/stats").respond(200)
            promise = resource.getMilestoneStats(1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/milestones/100/stats").respond(400)
            promise = resource.getMilestoneStats(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get unassigned userstories of a project", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstories?milestone=null&project=1").respond(200)
            promise = resource.getUnassignedUserStories(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstories?milestone=null&project=100").respond(400)
            promise = resource.getUnassignedUserStories(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the userstories of a project", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstories?project=1").respond(200)
            promise = resource.getUserStories(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstories?project=100").respond(400)
            promise = resource.getUserStories(100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the userstories of a milestone", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstories?milestone=1&project=1").respond(200)
            promise = resource.getMilestoneUserStories(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstories?milestone=100&project=1").respond(400)
            promise = resource.getMilestoneUserStories(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a userstory", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstories/1?project=1").respond(200)
            promise = resource.getUserStory(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstories/100?project=1").respond(400)
            promise = resource.getUserStory(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the tasks of a milestone", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/tasks?milestone=1&project=1").respond(200)
            promise = resource.getTasks(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/tasks?milestone=100&project=1").respond(400)
            promise = resource.getTasks(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/tasks?project=1").respond(200)
            promise = resource.getTasks(1)
            promise.should.be.fullfilled
            httpBackend.flush()

        it "should allow to get the issues of a project", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/issues?project=1").respond(200)
            promise = resource.getIssues(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issues?project=100").respond(400)
            promise = resource.getIssues(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issues?filters=test&project=1").respond(200)
            promise = resource.getIssues(1, {"filters": "test"})
            promise.should.be.fullfilled
            httpBackend.flush()

        it "should allow to get a issue", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/issues/1?project=1").respond(200)
            promise = resource.getIssue(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issues/100?project=1").respond(400)
            promise = resource.getIssue(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a task", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/tasks/1?project=1").respond(200)
            promise = resource.getTask(1, 1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/tasks/100?project=1").respond(400)
            promise = resource.getTask(1, 100)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to search", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/search?get_all=false&project=1&text=test").respond(200)
            promise = resource.search(1, "test", false)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/search?get_all=false&project=1&text=bad").respond(400)
            promise = resource.search(1, "bad", false)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to users", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/users?project=1").respond(200)
            promise = resource.getUsers(1)
            promise.should.be.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/users?project=100").respond(400)
            promise = resource.getUsers(100)
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/users").respond(200)
            promise = resource.getUsers()
            promise.should.be.fullfilled
            httpBackend.flush()

        it "should allow to create a issue", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/issues", {"test": "test", "project": 1}).respond(200)
            promise = resource.createIssue(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/issues", {"test": "bad", "project": 1}).respond(400)
            promise = resource.createIssue(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a user story", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/userstories?", {"test": "test"}).respond(200)
            promise = resource.createUserStory({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/userstories?", {"test": "bad"}).respond(400)
            promise = resource.createUserStory({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a bulk of user stories", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/userstories/bulk_create", {"test": "test", "projectId": 1}).respond(200)
            promise = resource.createBulkUserStories(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/userstories/bulk_create", {"test": "bad", "projectId": 1}).respond(400)
            promise = resource.createBulkUserStories(1, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a bulk of tasks", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/tasks/bulk_create", {"test": "test", "projectId": 1, "usId": 2}).respond(200)
            promise = resource.createBulkTasks(1, 2, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/tasks/bulk_create", {"test": "bad", "projectId": 1, "usId": 2}).respond(400)
            promise = resource.createBulkTasks(1, 2, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a bulk of tasks", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/tasks/bulk_create", {"test": "test", "projectId": 1, "usId": 2}).respond(200)
            promise = resource.createBulkTasks(1, 2, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/tasks/bulk_create", {"test": "bad", "projectId": 1, "usId": 2}).respond(400)
            promise = resource.createBulkTasks(1, 2, {"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow update the user stories order in bulk", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/userstories/bulk_update_order",
                {"projectId": 1, "bulkStories": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkUserStoriesOrder(1, [[1, 2], [2, 1]])
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST(
                "#{APIURL}/userstories/bulk_update_order",
                {"projectId": 100, "bulkStories": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkUserStoriesOrder(100, [[1, 2], [2, 1]])
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow set the milestone of a user story", inject (resource) ->
            httpBackend.expectPATCH("#{APIURL}/userstories/1", {"milestone": 2}).respond(200)
            promise = resource.setUsMilestone(1, 2)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPATCH("#{APIURL}/userstories/100", {"milestone": 1}).respond(400)
            promise = resource.setUsMilestone(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow create a milestone", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/milestones", {"project": 1, "test": "test"}).respond(200)
            promise = resource.createMilestone(1, {"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/milestones", {"project": 100, "test": "test"}).respond(400)
            promise = resource.createMilestone(100, {"test": "test"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get a wiki page", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/wiki?project=1&slug=test").respond(200, "wiki")
            promise = resource.getWikiPage(1, "test")
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/wiki?project=1&slug=bad").respond(400, "wiki")
            promise = resource.getWikiPage(1, "bad")
            promise.should.be.rejected
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/wiki?project=1&slug=empty").respond(200, [])
            promise = resource.getWikiPage(1, "empty")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a task", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/tasks?", {"test": "test"}).respond(200)
            promise = resource.createTask({"test": "test"})
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/tasks?", {"test": "bad"}).respond(400)
            promise = resource.createTask({"test": "bad"})
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to restore a wiki page", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/wiki/test/restore?version=1").respond(200)
            promise = resource.restoreWikiPage("test", 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/wiki/bad/restore?version=1").respond(400)
            promise = resource.restoreWikiPage("bad", 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to create a wiki page", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/wiki", {"content": "test", "slug": "test-slug", "project": 1}).respond(200)
            promise = resource.createWikiPage(1, "test-slug", "test")
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectPOST("#{APIURL}/wiki", {"content": "bad", "slug": "test-slug", "project": 1}).respond(400)
            promise = resource.createWikiPage(1, "test-slug", "bad")
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the attachments of an issue", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=1").respond(200)
            promise = resource.getIssueAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/issues/attachments?object_id=1&project=100").respond(400)
            promise = resource.getIssueAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the attachments of a task", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/tasks/attachments?object_id=1&project=1").respond(200)
            promise = resource.getTaskAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/tasks/attachments?object_id=1&project=100").respond(400)
            promise = resource.getTaskAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the attachments of an issue", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstories/attachments?object_id=1&project=1").respond(200)
            promise = resource.getUserStoryAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/userstories/attachments?object_id=1&project=100").respond(400)
            promise = resource.getUserStoryAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the attachments of an issue", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/wiki/attachments?object_id=1&project=1").respond(200)

            promise = resource.getWikiPageAttachments(1, 1)
            httpBackend.flush()
            promise.should.be.fullfilled

            httpBackend.expectGET("#{APIURL}/wiki/attachments?object_id=1&project=100").respond(400)
            promise = resource.getWikiPageAttachments(100, 1)
            promise.should.be.rejected
            httpBackend.flush()

        it "should allow to get the site info", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/sites")
            promise = resource.getSiteInfo()
            promise.should.fullfilled
            httpBackend.flush()

        it "should allow to get the user stories statuses", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/userstory-statuses?project=1").respond(200)
            promise = resource.getUserStoryStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstory-statuses?project=1&test=test").respond(200)
            promise = resource.getUserStoryStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/userstory-statuses?project=100").respond(400)
            promise = resource.getUserStoryStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a user stories status", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/userstory-statuses?", {"test": "test"}).respond(200)
            promise = resource.createUserStoryStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/userstory-statuses?", {"test": "bad"}).respond(400)
            promise = resource.createUserStoryStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the user stories statuses orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/userstory-statuses/bulk_update_order",
                {"project": 1, "bulk_userstory_statuses": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkUserStoryStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/userstory-statuses/bulk_update_order",
                {"project": 100, "bulk_userstory_statuses": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkUserStoryStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the user stories points", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/points?project=1").respond(200)
            promise = resource.getPoints(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/points?project=1&test=test").respond(200)
            promise = resource.getPoints(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/points?project=100").respond(400)
            promise = resource.getPoints(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a user stories status", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/points?", {"test": "test"}).respond(200)
            promise = resource.createPoints({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/points?", {"test": "bad"}).respond(400)
            promise = resource.createPoints({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the user stories points orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/points/bulk_update_order",
                {"project": 1, "bulk_points": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkPointsOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/points/bulk_update_order",
                {"project": 100, "bulk_points": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkPointsOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the tasks statuses", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/task-statuses?project=1").respond(200)
            promise = resource.getTaskStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/task-statuses?project=1&test=test").respond(200)
            promise = resource.getTaskStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/task-statuses?project=100").respond(400)
            promise = resource.getTaskStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a tasks status", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/task-statuses?", {"test": "test"}).respond(200)
            promise = resource.createTaskStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/task-statuses?", {"test": "bad"}).respond(400)
            promise = resource.createTaskStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the tasks statuses orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/task-statuses/bulk_update_order",
                {"project": 1, "bulk_task_statuses": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkTaskStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/task-statuses/bulk_update_order",
                {"project": 100, "bulk_task_statuses": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkTaskStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the issues statuses", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/issue-statuses?project=1").respond(200)
            promise = resource.getIssueStatuses(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issue-statuses?project=1&test=test").respond(200)
            promise = resource.getIssueStatuses(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issue-statuses?project=100").respond(400)
            promise = resource.getIssueStatuses(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a issues status", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/issue-statuses?", {"test": "test"}).respond(200)
            promise = resource.createIssueStatus({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/issue-statuses?", {"test": "bad"}).respond(400)
            promise = resource.createIssueStatus({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the issues statuses orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/issue-statuses/bulk_update_order",
                {"project": 1, "bulk_issue_statuses": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkIssueStatusesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/issue-statuses/bulk_update_order",
                {"project": 100, "bulk_issue_statuses": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkIssueStatusesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the issues types", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/issue-types?project=1").respond(200)
            promise = resource.getIssueTypes(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issue-types?project=1&test=test").respond(200)
            promise = resource.getIssueTypes(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/issue-types?project=100").respond(400)
            promise = resource.getIssueTypes(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a issues type", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/issue-types?", {"test": "test"}).respond(200)
            promise = resource.createIssueType({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/issue-types?", {"test": "bad"}).respond(400)
            promise = resource.createIssueType({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the issues types orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/issue-types/bulk_update_order",
                {"project": 1, "bulk_issue_types": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkIssueTypesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/issue-types/bulk_update_order",
                {"project": 100, "bulk_issue_types": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkIssueTypesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the priorities", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/priorities?project=1").respond(200)
            promise = resource.getPriorities(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/priorities?project=1&test=test").respond(200)
            promise = resource.getPriorities(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/priorities?project=100").respond(400)
            promise = resource.getPriorities(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a priority", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/priorities?", {"test": "test"}).respond(200)
            promise = resource.createPriority({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/priorities?", {"test": "bad"}).respond(400)
            promise = resource.createPriority({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the priorities orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/priorities/bulk_update_order",
                {"project": 1, "bulk_priorities": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkPrioritiesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/priorities/bulk_update_order",
                {"project": 100, "bulk_priorities": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkPrioritiesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()

        it "should allow to get the severities", inject (resource) ->
            httpBackend.expectGET("#{APIURL}/severities?project=1").respond(200)
            promise = resource.getSeverities(1)
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/severities?project=1&test=test").respond(200)
            promise = resource.getSeverities(1, {"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectGET("#{APIURL}/severities?project=100").respond(400)
            promise = resource.getSeverities(100)
            promise.should.rejected
            httpBackend.flush()

        it "should allow to create a severity", inject (resource) ->
            httpBackend.expectPOST("#{APIURL}/severities?", {"test": "test"}).respond(200)
            promise = resource.createSeverity({"test": "test"})
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST("#{APIURL}/severities?", {"test": "bad"}).respond(400)
            promise = resource.createSeverity({"test": "bad"})
            promise.should.rejected
            httpBackend.flush()

        it "should allow to bulk update the severities orders", inject (resource) ->
            httpBackend.expectPOST(
                "#{APIURL}/severities/bulk_update_order",
                {"project": 1, "bulk_severities": [[1, 2], [2, 1]]}
            ).respond(200)
            promise = resource.updateBulkSeveritiesOrder(1, [[1, 2], [2, 1]])
            promise.should.fullfilled
            httpBackend.flush()

            httpBackend.expectPOST(
                "#{APIURL}/severities/bulk_update_order",
                {"project": 100, "bulk_severities": [[1, 2], [2, 1]]}
            ).respond(400)
            promise = resource.updateBulkSeveritiesOrder(100, [[1, 2], [2, 1]])
            promise.should.rejected
            httpBackend.flush()
