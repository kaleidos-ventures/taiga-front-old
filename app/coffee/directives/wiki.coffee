
gmMarkitupConstructor = ($parse) ->
    require: "?ngModel",
    link: (scope, elm, attrs, ngModel) ->
        wikiHelpUrl = "https://github.com/fletcher/MultiMarkdown/blob/master/Documentation/Markdown%20Syntax.md"
        openHelp = () ->
            window.open(wikiHelpUrl,'_blank')

        markdownSettings =
            nameSpace: 'markdown'
            onShiftEnter: {keepDefault:false, openWith:'\n\n'}
            previewParser: (content) -> markdown.toHTML(content)
            markupSet: [
                {name:'First Level Heading', key:"1", placeHolder:'Your title here...', closeWith:(markItUp) -> markdownTitle(markItUp, '=') },
                {name:'Second Level Heading', key:"2", placeHolder:'Your title here...', closeWith:(markItUp) -> markdownTitle(markItUp, '-') },
                {name:'Heading 3', key:"3", openWith:'### ', placeHolder:'Your title here...' },
                {name:'Heading 4', key:"4", openWith:'#### ', placeHolder:'Your title here...' },
                {name:'Heading 5', key:"5", openWith:'##### ', placeHolder:'Your title here...' },
                {name:'Heading 6', key:"6", openWith:'###### ', placeHolder:'Your title here...' },
                {separator:'---------------' },
                {name:'Bold', key:"B", openWith:'**', closeWith:'**'},
                {name:'Italic', key:"I", openWith:'_', closeWith:'_'},
                {separator:'---------------' },
                {name:'Bulleted List', openWith:'- ' },
                {name:'Numeric List', openWith:(markItUp) -> markItUp.line+'. '},
                {separator:'---------------' },
                {name:'Picture', key:"P", replaceWith:'![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'},
                {name:'Link', key:"L", openWith:'[', closeWith:']([![Url:!:http://]!] "[![Title]!]")', placeHolder:'Your text to link here...' },
                {separator:'---------------'},
                {name:'Quotes', openWith:'> '},
                {name:'Code Block / Code', openWith:'(!(\t|!|`)!)', closeWith:'(!(`)!)'},
                {separator:'---------------'},
                {name:'Preview', call:'preview', className:"preview"}
                {separator:'---------------'},
                {name:'Help', call: openHelp , className:"help"}
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



GmRenderMarkdownDirective = ($rootScope, $parse) ->
    parseMarkdownLinks = (scope, tree) ->
        if tree.length == 0
            return

        if tree[0] == "link"
            wikiName = tree[1].href

            if _.str.startsWith(wikiName, "/")
                return
            if _.str.endsWith(wikiName, "/")
                return

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

                tree = markdown.parse(data.replace("\r", ""))
                for item in tree[1..tree.length]
                    parseMarkdownLinks(scope, item)

                element.html(markdown.toHTML(tree))


module = angular.module('greenmine.directives.wiki', [])
module.directive('gmMarkitup', ["$parse", gmMarkitupConstructor])
module.directive("gmRenderMarkdown", ["$rootScope", "$parse", GmRenderMarkdownDirective])
