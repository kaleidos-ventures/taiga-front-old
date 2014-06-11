# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


gmMarkitupConstructor = ($rootScope, $parse, $i18next, $location, rs, gmWiki) ->
    require: "?ngModel",
    link: (scope, elm, attrs, ngModel) ->
        openHelp = () ->
            window.open($rootScope.urls.wikiHelpUrl(), '_blank')

        preview = () ->
            gmWiki.render($rootScope.projectId, elm.val()).then (result) ->
                $("##{attrs.previewId}").show()
                $("##{attrs.previewId}").html(result)

        markdownSettings =
            nameSpace: 'markdown'
            onShiftEnter: {keepDefault:false, openWith:'\n\n'}
            markupSet: [
                {
                    name: $i18next.t('wiki-editor.heading-1')
                    key: "1"
                    placeHolder: $i18next.t('wiki-editor.placeholder')
                    closeWith: (markItUp) -> markdownTitle(markItUp, '=')
                },
                {
                    name: $i18next.t('wiki-editor.heading-2')
                    key: "2"
                    placeHolder: $i18next.t('wiki-editor.placeholder')
                    closeWith: (markItUp) -> markdownTitle(markItUp, '-')
                },
                {
                    name: $i18next.t('wiki-editor.heading-3')
                    key: "3"
                    openWith: '### '
                    placeHolder: $i18next.t('wiki-editor.placeholder')
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.bold')
                    key: "B"
                    openWith: '**'
                    closeWith: '**'
                },
                {
                    name: $i18next.t('wiki-editor.italic')
                    key: "I"
                    openWith: '_'
                    closeWith: '_'
                },
                {
                    name: $i18next.t('wiki-editor.strike')
                    key: "S"
                    openWith: '~~'
                    closeWith: '~~'
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.bulleted-list')
                    openWith: '- '
                },
                {
                    name: $i18next.t('wiki-editor.numeric-list')
                    openWith: (markItUp) -> markItUp.line+'. '
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.picture')
                    key: "P"
                    replaceWith: '![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'
                },
                {
                    name: $i18next.t('wiki-editor.link')
                    key: "L"
                    openWith: '['
                    closeWith: ']([![Url:!:http://]!] "[![Title]!]")'
                    placeHolder: $i18next.t('wiki-editor.link-placeholder')
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.quotes')
                    openWith: '> '
                },
                {
                    name: $i18next.t('wiki-editor.code-block')
                    openWith: '```\n'
                    closeWith: '\n```'
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.preview')
                    call: preview
                    className: "preview-icon"
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.help')
                    call: openHelp
                    className: "help"
                }
            ]
            afterInsert: (event) ->
                target = angular.element(event.textarea)
                ngModel.$setViewValue(target.val())

        markdownTitle = (markItUp, char) ->
            heading = ''
            n = $.trim(markItUp.selection or markItUp.placeHolder).length

            for i in [0..n-1]
                heading += char

            return '\n'+heading+'\n'

        element = angular.element(elm)

        emojiStrategy = {
            match: /(^|\s):(\w*)$/,
            search: (term, callback) ->
                regexp = new RegExp('^' + term)
                callback(
                    (key.substring(5) for key in _.keys($.emoticons.list) when regexp.test(key.substring(5)))
                )
            template: (value) ->
                return "<img src=\"/img/emoticons/#{value}.png\"></img> #{value}"
            replace: (value) ->
                return "$1:#{value}: "
            maxCount: 5
        }
        usersStrategy = {
            match: /(^|\s)@([\w-]*)$/,
            search: (term, callback) ->
                regexp = new RegExp('^' + term)
                filterUser = (regexp, user) ->
                    return _.any [
                        regexp.test(user.full_name)
                        regexp.test(user.username)
                        regexp.test(user.email)
                    ]

                userData = (user) ->
                    {username: user.username, name: user.full_name}

                getUsersList = () ->
                    users = $rootScope.constants.usersList
                    return (userData(user) for user in users when filterUser(regexp, user))

                callback(getUsersList())
            template: (value) ->
                return "#{value.name}"
            replace: (value) ->
                return "$1_**@#{value.name}**_"
            maxCount: 5
        }
        userStoryStrategy = {
            match: /(^|\s):us#(\d+)$/,
            search: (ref, callback) ->
                resolvePromise = rs.resolve(pslug: $rootScope.projectSlug, usref: ref)
                resolvePromise.then (data) ->
                    if data.us
                        promise = rs.getUserStory(data.project, data.us)
                        promise.then (data) ->
                            objects = []
                            if data
                                objects[0] = {
                                    id: data.id
                                    ref: data.ref
                                    subject: data.subject
                                }
                            callback(objects, false)
                        promise.then null, ->
                            callback([], false)
                    else
                        callback([], false)
                resolvePromise.then null, ->
                    callback([], false)
            template: (value) ->
                return "US ##{value.ref} - #{value.subject}"
            replace: (value) ->
                return "$1[US ##{value.ref}](:us:#{value.ref} \"US ##{value.ref} - #{value.subject}\")"
            maxCount: 1
        }
        taskStrategy = {
            match: /(^|\s):task#(\d+)$/,
            search: (ref, callback) ->
                resolvePromise = rs.resolve(pslug: $rootScope.projectSlug, taskref: ref)
                resolvePromise.then (data) ->
                    if data.task
                        promise = rs.getTask(data.project, data.task)
                        promise.then (data) ->
                            objects = []
                            if data
                                objects[0] = {
                                    id: data.id
                                    ref: data.ref
                                    subject: data.subject
                                }
                            callback(objects, false)
                        promise.then null, ->
                            callback([], false)
                    else
                        callback([], false)
                resolvePromise.then null, ->
                    callback([], false)
            template: (value) ->
                return "Task ##{value.ref} - #{value.subject}"
            replace: (value) ->
                return "$1[Task ##{value.ref}](:task:#{value.ref} \"Task ##{value.ref} - #{value.subject}\")"
            maxCount: 1
        }
        issueStrategy = {
            match: /(^|\s):issue#(\d+)$/,
            search: (ref, callback) ->
                resolvePromise = rs.resolve(pslug: $rootScope.projectSlug, issueref: ref)
                resolvePromise.then (data) ->
                    if data.issue
                        promise = rs.getIssue(data.project, data.issue)
                        promise.then (data) ->
                            objects = []
                            if data
                                objects[0] = {
                                    id: data.id
                                    ref: data.ref
                                    subject: data.subject
                                }
                            callback(objects, false)
                        promise.then null, ->
                            callback([], false)
                    else
                        callback([], false)
                resolvePromise.then null, ->
                    callback([], false)
            template: (value) ->
                return "Issue ##{value.ref} - #{value.subject}"
            replace: (value) ->
                return "$1[Issue ##{value.ref}](:issue:#{value.ref} \"Issue ##{value.ref} - #{value.subject}\")"
            maxCount: 1
        }
        objectsStrategy = {
            match: /(^|\s)\$\$\$(.*)$/,
            search: (term, callback) ->
                promise = rs.search($rootScope.projectId, term, true)
                promise.then (data) ->
                    objects = []
                    for us in data.userstories
                        objects.push {
                            type: 'us'
                            ref: us.ref
                            name: us.subject
                        }

                    for task in data.tasks
                        objects.push {
                            type: 'task'
                            ref: task.ref
                            name: task.subject
                        }

                    for issue in data.issues
                        objects.push {
                            type: 'issue'
                            ref: issue.ref
                            name: issue.subject
                        }

                    for wikipage in data.wikipages
                        objects.push {
                            type: 'wikipage'
                            ref: wikipage.slug
                            name: wikipage.slug
                        }
                    callback(objects, false)
                promise.then null, ->
                    callback([], false)
            template: (value) ->
                return "[#{value.type.toUpperCase()}] #{value.name}"

            replace: (value) ->
                switch value.type
                    when 'us' then return "$1[US##{value.ref}](:us:#{value.ref} \"#{value.name}\")"
                    when 'issue' then return "$1[Issue##{value.ref}](:issue:#{value.ref} \"#{value.name}\")"
                    when 'task' then return "$1[Task##{value.ref}](:task:#{value.ref} \"#{value.name}\")"
                    when 'wikipage' then return "$1[#{value.name}](#{value.ref} \"#{value.name}\")"
                    else ""
            maxCount: 10
        }
        element.textcomplete([emojiStrategy,
                              usersStrategy,
                              userStoryStrategy,
                              taskStrategy,
                              issueStrategy,
                              objectsStrategy])

        element.markItUp(markdownSettings)

        element.on "keypress", (event) ->
            scope.$apply()

        scope.$on "wiki:clean-previews", (event) ->
            $("##{attrs.previewId}").hide()
            $("##{attrs.previewId}").html("")

class GmRenderMarkdownService extends TaigaBaseService
    @.$inject = ["resource", "$q"]

    constructor: (@rs, @q) ->
        super()

    render: (projectId, text) ->
        defered = @q.defer()

        @rs.renderWiki(projectId, text).then (response) ->
            defered.resolve(response.data)

        @rs.renderWiki(projectId, text).then null, () ->
            defered.reject()

        return defered.promise

moduleDeps = ['i18next', 'taiga.services.resource']
module = angular.module('gmWiki', moduleDeps)
module.directive('gmMarkitup', ["$rootScope", "$parse", "$i18next",
                                "$location", "resource", "gmWiki",
                                gmMarkitupConstructor])
module.service("gmWiki", GmRenderMarkdownService)
