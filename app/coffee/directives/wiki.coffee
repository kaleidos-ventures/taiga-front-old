
gmMarkitupConstructor = ($parse) ->
    require: "?ngModel",
    link: (scope, elm, attrs, ngModel) ->
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
    link: (scope, elm, attrs) ->
        element = angular.element(elm)
        projectId = scope.projectId
        urls = $rootScope.urls

        scope.$watch attrs.gmRenderMarkdown, ->
            data = scope.$eval(attrs.gmRenderMarkdown)
            if data != undefined

                tree = markdown.parse(data.replace("\r", ""))
                for item in tree[1]
                    if _.isArray(item) and item[0] == "link"
                        wikiName = item[1].href
                        if not _.str.startsWith("/") and not _.str.endsWith("/")
                            item[1].href = urls.wikiUrl(projectId, item[1].href)

                element.html(markdown.toHTML(tree))


module = angular.module('greenmine.directives.wiki', [])
module.directive('gmMarkitup', ["$parse", gmMarkitupConstructor])
module.directive("gmRenderMarkdown", ["$rootScope", "$parse", GmRenderMarkdownDirective])
