
gmMarkitupConstructor = ($parse, $i18next, $sanitize) ->
    require: "?ngModel",
    link: (scope, elm, attrs, ngModel) ->
        wikiHelpUrl = "https://github.com/fletcher/MultiMarkdown/blob/master/Documentation/Markdown%20Syntax.md"
        openHelp = () ->
            window.open(wikiHelpUrl,'_blank')

        markdownSettings =
            nameSpace: 'markdown'
            onShiftEnter: {keepDefault:false, openWith:'\n\n'}
            previewParser: (content) -> $sanitize(markdown.toHTML(content))
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
                    name: $i18next.t('wiki-editor.heading-4')
                    key: "4"
                    openWith: '#### '
                    placeHolder: $i18next.t('wiki-editor.placeholder')
                },
                {
                    name: $i18next.t('wiki-editor.heading-5')
                    key: "5"
                    openWith: '##### '
                    placeHolder: $i18next.t('wiki-editor.placeholder')
                },
                {
                    name: $i18next.t('wiki-editor.heading-6')
                    key: "6"
                    openWith: '###### '
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
                    openWith: '(!(\t|!|`)!)'
                    closeWith: '(!(`)!)'
                },
                {
                    separator: '---------------'
                },
                {
                    name: $i18next.t('wiki-editor.preview')
                    call: 'preview'
                    className: "preview"
                }
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
        element.markItUp(markdownSettings)

        element.on "keypress", (event) ->
            scope.$apply()



GmRenderMarkdownDirective = ($rootScope, $parse, $sanitize) ->
    parseMarkdownLinks = (scope, tree) ->
        if tree.length == 0
            return

        if tree[0] == "link"
            if tree[1].href == _.string.slugify(tree[1].href)
                # It's an internal link to a wiki page
                tree[1].href = scope.urls.wikiUrl(scope.projectId, tree[1].href)
            return null

        for t in tree
            parseMarkdownLinks(scope, t) if _.isArray(t)

    return (scope, elm, attrs) ->
        element = angular.element(elm)
        projectId = scope.projectId

        scope.$watch attrs.gmRenderMarkdown, ->
            data = scope.$eval(attrs.gmRenderMarkdown)
            if data != undefined
                tree = markdown.parse(data.replace("\r", ""), 'Maruku')
                for item in tree[1..tree.length]
                    parseMarkdownLinks(scope, item)

                element.html($sanitize(markdown.toHTML(tree)))


module = angular.module('greenmine.directives.wiki', [])
module.directive('gmMarkitup', ["$parse", "$i18next", "$sanitize", gmMarkitupConstructor])
module.directive("gmRenderMarkdown", ["$rootScope", "$parse", "$sanitize", GmRenderMarkdownDirective])
