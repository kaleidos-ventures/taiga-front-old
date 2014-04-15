beforeEach(module('taiga.directives.history'))
beforeEach(module('gmWiki'))

describe "GmHistoryDirective", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
        <div class="history-issue" gm-history="{{ testType }}" ng-model="testHistorical">
            <div class="history-items-container"></div>
        </div>

        <script type="text/angular-template" id="change-template">
            <ul class="history-items">
                <li class="history-item" ng-repeat="hitem in historyItems">
                    <span class="user">{{ hitem.by.full_name }}</span>
                    <span class="date">{{ hitem.modified_date }}</span>
                    <div class="changes">
                        <div class="change" ng-repeat="change in hitem.changes">
                            <span class="field">{{ change.name }}</span>
                            <span class="old">{{ change.old }}</span>
                            <span class="new">{{ change.new }}</span>
                        </div>
                    </div>
                    <div class="comment">{{ hitem.comment }}</div>
                </li>
            </ul>
        </script>
    """

    constants = {
        users: {
            1: {full_name: "User 1"}
            2: {ful_name: "User 2"}
        },
        usStatuses: {
            1: {name: "Issue status 1"}
            2: {name: "Issue status 2"}
        },
        issueTypes: {
            1: {name: "Type 1"}
            2: {name: "Type 2"}
        },
        issueStatuses: {
            1: {name: "Issue status 1"}
            2: {name: "Issue status 2"}
        },
        priorities: {
            1: {name: "Priority 1"}
            2: {name: "Priority 2"}
        },
        severities: {
            1: {name: "Severity 1"}
            2: {name: "Severity 2"}
        },
        taskStatuses: {
            1: {name: "Issue status 1"}
            2: {name: "Issue status 2"}
        }
    }


    userStoryOnlyCommentHistorical = [
        {
            id: 1277,
            content_type: "userstory",
            created_date: "2014-03-14T21:24:33.099Z",
            user: 1,
            comment: "",
            changed_fields: {}
        }
    ]
    userStoryHistorical = [
        {
            id: 1277,
            content_type: "userstory",
            created_date: "2014-03-14T21:24:33.099Z",
            user: 1,
            comment: "lololololo",
            changed_fields: {
                status: {
                    new: 1,
                    old: null,
                    name: "status"
                },
                assigned_to: {
                    new: 1,
                    old: null,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                client_requirement: {
                    new: true,
                    old: null,
                    name: "client requirement"
                },
                team_requirement: {
                    new: true,
                    old: null,
                    name: "team requirement"
                },
                is_blocked: {
                    new: true,
                    old: null,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: null,
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        },
        {
            id: 1278,
            content_type: "userstory",
            created_date: "2014-04-14T21:24:33.099Z",
            user: null,
            comment: "",
            changed_fields: {
                status: {
                    new: 1,
                    old: 6,
                    name: "status"
                },
                assigned_to: {
                    new: 1,
                    old: 6,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                client_requirement: {
                    new: true,
                    old: false,
                    name: "client requirement"
                },
                team_requirement: {
                    new: true,
                    old: false,
                    name: "team requirement"
                },
                is_blocked: {
                    new: true,
                    old: false,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: ["6"],
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        }
    ]
    issueHistorical = [
        {
            id: 1277,
            content_type: "issue",
            created_date: "2014-03-14T21:24:33.099Z",
            user: 1,
            comment: "lololololo",
            changed_fields: {
                type: {
                    new: 1,
                    old: null,
                    name: "type"
                },
                status: {
                    new: 1,
                    old: null,
                    name: "status"
                },
                priority: {
                    new: 1,
                    old: null,
                    name: "priority"
                },
                severity: {
                    new: 1,
                    old: null,
                    name: "severity"
                },
                assigned_to: {
                    new: 1,
                    old: null,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                is_blocked: {
                    new: true,
                    old: null,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: null,
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        },
        {
            id: 1278,
            content_type: "issue",
            created_date: "2014-04-14T21:24:33.099Z",
            user: null,
            comment: "",
            changed_fields: {
                type: {
                    new: 1,
                    old: 6,
                    name: "type"
                },
                status: {
                    new: 1,
                    old: 6,
                    name: "status"
                },
                priority: {
                    new: 1,
                    old: 6,
                    name: "priority"
                },
                severity: {
                    new: 1,
                    old: 6,
                    name: "severity"
                },
                assigned_to: {
                    new: 1,
                    old: 6,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                is_blocked: {
                    new: true,
                    old: false,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: ["6"],
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        }
    ]
    taskHistorical = [
        {
            id: 1277,
            content_type: "task",
            created_date: "2014-03-14T21:24:33.099Z",
            user: 1,
            comment: "lololololo",
            changed_fields: {
                status: {
                    new: 1,
                    old: null,
                    name: "status"
                },
                assigned_to: {
                    new: 1,
                    old: null,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                is_iocaine: {
                    new: true,
                    old: null,
                    name: "is_iocaine"
                },
                is_blocked: {
                    new: true,
                    old: null,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: null,
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        },
        {
            id: 1278,
            content_type: "task",
            created_date: "2014-04-14T21:24:33.099Z",
            user: null,
            comment: "",
            changed_fields: {
                status: {
                    new: 1,
                    old: 6,
                    name: "status"
                },
                assigned_to: {
                    new: 1,
                    old: 6,
                    name: "assigned to"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: null,
                    name: "tags"
                },
                subject: {
                    new: "test subject",
                    old: null,
                    name: "subject"
                },
                description: {
                    new: "test description",
                    old: null,
                    name: "description"
                },
                is_iocaine: {
                    new: true,
                    old: false,
                    name: "is_iocaine"
                },
                is_blocked: {
                    new: true,
                    old: false,
                    name: "is blocked"
                },
                blocked_note: {
                    new: "test",
                    old: null,
                    name: "blocked note"
                },
                watchers: {
                    new: ["1", "2"],
                    old: ["6"],
                    name: "watchers"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                }
            }
        }
    ]

    beforeEach(inject((_$compile_, _$rootScope_, gmWiki) ->
        element = angular.element(template)
        $compile = _$compile_
        $rootScope = _$rootScope_
        $rootScope.constants = constants
    ))

    it "should allow to draw an empty historical",  inject ($model)->
        $rootScope.testHistorical = {models : []}
        $rootScope.testType = ""

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...

    it "should allow to draw a user story historical 2",  inject ($model)->
        $rootScope.testHistorical = {
            models : _.map(userStoryOnlyCommentHistorical, (item) =>
                $model.make_model("userstory-history", item))
        }
        $rootScope.testType = "userstory"

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...

    it "should allow to draw a user story historical",  inject ($model)->
        $rootScope.testHistorical = {
            models : _.map(userStoryHistorical, (item) => $model.make_model("userstory-history", item))
        }
        $rootScope.testType = "userstory"

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...

    it "should allow to draw an issue historical",  inject ($model)->
        $rootScope.testHistorical = {
            models : _.map(issueHistorical, (item) => $model.make_model("issue-history", item))
        }
        $rootScope.testType = "issue"

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...

    it "should allow to draw a task historical",  inject ($model)->
        $rootScope.testHistorical = {
            models : _.map(issueHistorical, (item) => $model.make_model("issue-history", item))
        }
        $rootScope.testType = "task"

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...
