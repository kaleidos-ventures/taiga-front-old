
gmMarkitupConstructor = ($rootScope, $parse, $i18next, $sanitize, $location, rs) ->
    require: "?ngModel",
    link: (scope, elm, attrs, ngModel) ->
        openHelp = () ->
            window.open($rootScope.urls.wikiHelpUrl(scope.projectSlug), '_blank')

        preview = () ->
            $("##{attrs.previewId}").show()
            $("##{attrs.previewId}").html($.emoticons.replaceExcludingPre(marked(elm.val())))

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
                        regexp.test(user.first_name)
                        regexp.test(user.last_name)
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
                return "$1@#{value.username} "
            maxCount: 5
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
        element.textcomplete([emojiStrategy, usersStrategy, objectsStrategy])

        element.markItUp(markdownSettings)

        element.on "keypress", (event) ->
            scope.$apply()

        scope.$on "wiki:clean-previews", (event) ->
            $("##{attrs.previewId}").hide()
            $("##{attrs.previewId}").html("")

GmRenderMarkdownDirective = ($rootScope, $parse, $sanitize) ->
    return (scope, elm, attrs) ->
        element = angular.element(elm)
        projectId = scope.projectId

        if not attrs.gmRenderMarkdown
            result = $.emoticons.replaceExcludingPre(marked(element.text()))
            element.html(result)

        scope.$watch attrs.gmRenderMarkdown, ->
            data = scope.$eval(attrs.gmRenderMarkdown)
            if data != undefined
                result = $.emoticons.replaceExcludingPre(marked(data))
                element.html(result)

wikiInit = ($routeParams, $rootScope) ->
    hljs.initHighlightingOnLoad()

    renderer = new marked.Renderer()

    renderer.realLink = renderer.link
    renderer.link = (href, title, text) ->
        if href == _.string.slugify(href)
            # It's an internal link to a wiki page
            renderer.realLink($rootScope.urls.wikiUrl($routeParams.pslug, href), title, text)
        else if href.indexOf(':us:') == 0
            renderer.realLink($rootScope.urls.userStoryUrl($routeParams.pslug, href.substring(4)), title, text)
        else if href.indexOf(':task:') == 0
            renderer.realLink($rootScope.urls.tasksUrl($routeParams.pslug, href.substring(6)), title, text)
        else if href.indexOf(':issue:') == 0
            renderer.realLink($rootScope.urls.issuesUrl($routeParams.pslug, href.substring(7)), title, text)
        else if href.indexOf(':sprint:') == 0
            renderer.realLink($rootScope.urls.taskboardUrl($routeParams.pslug, href.substring(11)), title, text)
        else
            renderer.realLink(@, href, title, text)

    renderer.realImage = renderer.image
    renderer.image = (href, title, text) ->
        if href.indexOf(':att:') == 0
            renderer.realImage(
                $rootScope.urls.attachmentUrl(
                    $routeParams.pslug,
                    'wikipage',
                    href.substring(5)
                ),
                title,
                text
            )
        else
            renderer.realImage(href, title, text)

    marked.setOptions {
        highlight: (code, lang) ->
            if lang
                return hljs.highlight(lang, code).value
            return hljs.highlightAuto(code).value
        sanitize: true
        renderer: renderer
    }


module = angular.module('taiga.directives.wiki', []).run ['$routeParams', '$rootScope', wikiInit ]
module.directive('gmMarkitup', ["$rootScope", "$parse", "$i18next",
                                "$sanitize", "$location", "resource",
                                gmMarkitupConstructor])
module.directive("gmRenderMarkdown", ["$rootScope", "$parse", "$sanitize", GmRenderMarkdownDirective])
