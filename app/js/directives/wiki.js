'use strict';

angular.module('greenmine.directives.wiki', []).
    directive('gmMarkitup', ["$parse", function($parse) {
        return {
            require: "?ngModel",
            link: function(scope, elm, attrs, ngModel) {
                var markdownSettings = {
                    nameSpace:          'markdown', // Useful to prevent multi-instances CSS conflict
                    onShiftEnter:       {keepDefault:false, openWith:'\n\n'},
                    previewParser: function(content) { return markdown.toHTML(content); },
                    markupSet: [
                        {name:'First Level Heading', key:"1", placeHolder:'Your title here...', closeWith:function(markItUp) { return markdownTitle(markItUp, '=') } },
                        {name:'Second Level Heading', key:"2", placeHolder:'Your title here...', closeWith:function(markItUp) { return markdownTitle(markItUp, '-') } },
                        {name:'Heading 3', key:"3", openWith:'### ', placeHolder:'Your title here...' },
                        {name:'Heading 4', key:"4", openWith:'#### ', placeHolder:'Your title here...' },
                        {name:'Heading 5', key:"5", openWith:'##### ', placeHolder:'Your title here...' },
                        {name:'Heading 6', key:"6", openWith:'###### ', placeHolder:'Your title here...' },
                        {separator:'---------------' },
                        {name:'Bold', key:"B", openWith:'**', closeWith:'**'},
                        {name:'Italic', key:"I", openWith:'_', closeWith:'_'},
                        {separator:'---------------' },
                        {name:'Bulleted List', openWith:'- ' },
                        {name:'Numeric List', openWith:function(markItUp) {
                            return markItUp.line+'. ';
                        }},
                        {separator:'---------------' },
                        {name:'Picture', key:"P", replaceWith:'![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'},
                        {name:'Link', key:"L", openWith:'[', closeWith:']([![Url:!:http://]!] "[![Title]!]")', placeHolder:'Your text to link here...' },
                        {separator:'---------------'},
                        {name:'Quotes', openWith:'> '},
                        {name:'Code Block / Code', openWith:'(!(\t|!|`)!)', closeWith:'(!(`)!)'},
                        {separator:'---------------'},
                        {name:'Preview', call:'preview', className:"preview"}
                    ],

                    afterInsert: function(event) {
                        var target = angular.element(event.textarea);
                        ngModel.$setViewValue(target.val())
                    }
                }

                // mIu nameSpace to avoid conflict.
                var markdownTitle = function(markItUp, char) {
                    var heading = '';
                    var n = $.trim(markItUp.selection||markItUp.placeHolder).length;
                    for(var i = 0; i < n; i++) {
                        heading += char;
                    }
                    return '\n'+heading+'\n';
                };

                var element = angular.element(elm);
                element.markItUp(markdownSettings);
                element.on("keypress", function(event) {
                    scope.$apply();
                });
            }
        };
    }]).
    directive("gmRenderMarkdown", ["$parse", function($parse) {
        return function(scope, elm, attrs) {
            var element = angular.element(elm);

            scope.$watch(attrs.gmRenderMarkdown, function() {
                var data = scope.$eval(attrs.gmRenderMarkdown);
                if (data !== undefined) {
                    // Regex for future page linking.
                    // /^\s*\([ \t]*(\S+)(?:[ \t]+(["'])(.*?)\2)?[ \t]*\)/;
                    element.html(markdown.toHTML(data.replace("\r", "")));
                }
            });
        };
    }]);
