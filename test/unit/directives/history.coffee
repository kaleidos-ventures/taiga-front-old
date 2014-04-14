beforeEach(module('taiga.directives.history'))
beforeEach(module('gmWiki'))

describe "GmHistoryDirective", ->
    element = null
    $rootScope = null
    $compile = null

    template = """
        <div class="history-issue" gm-history="issue" ng-model="testIssueHistorical">
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
        }
        issueTypes: {
            1: {name: "Type 1"}
            2: {name: "Type 2"}
        }
        issueStatuses: {
            1: {name: "Issue status 1"}
            2: {name: "Issue status 2"}
        }
        priorities: {
            1: {name: "Priority 1"}
            2: {name: "Priority 2"}
        }
        severities: {
            1: {name: "Severity 1"}
            2: {name: "Severity 2"}
        }
    }


    issueHistorical = [
        {
            id: 1278,
            created_date: "2014-04-14T21:24:33.099Z",
            content_type: "issue",
            object_id: 1,
            user: 1,
            comment: "lalalalala",
            fields: {
                id: 1,
                blocked_note: "test",
                ref: 1,
                modified_date: "2014-04-14T21:24:31.433Z",
                created_date: "2014-03-25T16:08:29.513Z",
                status: 1,
                tags: ["sequi", "a"],
                finished_date: "2014-04-14T21:24:31.432Z",
                is_blocked: true,
                subject: "test subject",
                owner: 1,
                watchers: ["2", "5"],
                milestone: null,
                description: "test description",
                type: 1,
                severity: 1,
                project: 1,
                assigned_to: 1,
                priority: 1
            },
            changed_fields: {
                description: {
                    new: "test description",
                    old: "Nisi odit aliquam quibusdam.",
                    name: "description"
                },
                blocked_note: {
                    new: "test",
                    old: "",
                    name: "blocked note"
                },
                is_blocked: {
                    new: true,
                    old: false,
                    name: "is blocked"
                },
                subject: {
                    new: "test subject",
                    old: "Add setting to allow regular users to create folders at the root level.",
                    name: "subject"
                },
                tags: {
                    new: ["sequi", "a"],
                    old: ["sequi", "a", "molestias"],
                    name: "tags"
                },
                status: {
                    new: 1,
                    old: 2,
                    name: "status"
                },
                type: {
                    new: 1,
                    old: 2,
                    name: "type"
                },
                watchers: {
                    new: ["1", "2"],
                    old: [],
                    name: "watchers"
                },
                severity: {
                    new: 1,
                    old: 2,
                    name: "severity"
                },
                finished_date: {
                    new: "2014-04-14T21:24:31.432Z",
                    old: null,
                    name: "finished date"
                },
                assigned_to: {
                    new: 1,
                    old: 2,
                    name: "assigned to"
                },
                priority: {
                    new: 1,
                    old: 2,
                    name: "priority"
                }
            }
        },
    ]

    beforeEach(inject((_$compile_, _$rootScope_, gmWiki) ->
        element = angular.element(template)
        $compile = _$compile_
        $rootScope = _$rootScope_


        $rootScope.constants = constants
    ))

    it "should allow to draw an issue historical",  inject ($model)->
        $rootScope.testIssueHistorical = {
            models : _.map(issueHistorical, (item) => $model.make_model("issue-history", item))
        }

        element = $compile(element)($rootScope)
        $rootScope.$digest()

        #TODO ...
