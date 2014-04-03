# Copyright 2014 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


transformers = {
    "membersToChoicesTransformer": (members, scope) ->
        return _.map members, (member) ->
            return {name: member.full_name, id: member.user}
}

renderTemplate = ($compile, $scope, template, context) ->
    tmpl = _.template("<div>#{template}</div>")(context)
    dom = angular.element(angular.element.parseHTML(tmpl))
    return $compile(dom)($scope)

makeTemplateContext = ($i18next, $scope, attrs, data) ->
    context = {
        className: attrs.gmPopoverClassName or ""
        emptyItem: attrs.gmPopoverEmptyItem or null
        model: attrs.gmPopoverModel or null
        title: attrs.gmPopoverTitle or null
        templateContent: ""
        objects: data
        main: attrs.gmPopover
    }

    if attrs.gmPopoverColorEnabled == "true"
        context.colorEnabled = true
    else
        context.colorEnabled = false

    if _.isString(context.title)
        if context.title.length > 0
            context.title = $i18next.t(context.title)
        else
            context.title = "untitled"

    if context.emptyItem != null
        context.emptyItem = $i18next.t(context.emptyItem)

    # Used by dialog variant
    if attrs.gmPopoverTitleBind
        context.title = $scope.$eval(attrs.gmPopoverTitleBind)

    return context


class PopoverController
    constructor: (@compile, @i18next, @scope, @element, @attrs, @template) ->
        _.bindAll(@)
        @.identifier = _.uniqueId("popover-")
        @element.on "$destroy", (event) =>
            @destroy()

    destroy: ->
        @element.popover("hide")
        @element.popover("destroy")

        if @popoverDom
            @popoverDom.off()
        @element.off()

        doc = angular.element(document)
        doc.off("click.#{@.identifier}")

        delete @.element
        delete @.attrs
        delete @.data
        delete @.scope

    makePopoverDom: (data) ->
        popoverScope = @scope.$new()
        popoverContext = makeTemplateContext(@i18next, popoverScope, @attrs, data)
        popoverDom = renderTemplate(@compile, popoverScope, @template, popoverContext)
        return popoverDom

    initializeMainEvents: ->
        @element.on "click", (event) =>
            event.stopPropagation()
            @element.popover("show")

        @element.on "shown.bs.popover", (event) =>
            doc = angular.element("body")
            doc.one "click.#{@.identifier}", (event) =>
                @element.popover("hide")
                doc.off("click.#{@.identifixer}")

    attachPopover: (data) ->
        popoverDom = @.makePopoverDom(data)
        popoverOpts = {
            content: popoverDom
            placement: "auto left"
            html: true
            container: "body"
            trigger: "manual"
        }

        # Hacky for not attach popover dom
        # to body. Usefull for tests.
        if @attrs.gmPopoverNoBody == "true"
            popoverOpts.container = false

        @element.popover(popoverOpts)

        popoverDom.on "click", ".btn-accept", (event) =>
            event.preventDefault()
            target = angular.element(event.currentTarget)

            @scope.$apply =>
                @scope.$eval(@attrs.gmPopover, {selectedId: target.data("id")})

            @element.popover("hide")

        popoverDom.on "click", ".btn-cancel", (event) =>
            event.preventDefault()
            @element.popover("hide")

        return popoverDom

    initialize: (data) ->
        @.initializeMainEvents()
        @.popoverDom = @.attachPopover(data)


class ColorPickerPopoverControler extends PopoverController
    attachPopover: (data) ->
        popoverDom = super(data)
        el = popoverDom.find(".colorSelector")
        el.coffeeColorPicker({color: {hue:100, sat: 100, lit: 25}})

        el.on "pick", (event, color) =>
            @scope.$apply =>
                @scope.$eval(@attrs.gmPopover, {"$color": color})

            @element.popover("hide")

        return popoverDom


GmGenericChoicePopover = ($compile, $i18next) ->
    template = """
    <div class="<%- className %>">
        <% if (title) { %>
        <p class="title"><%- title %></p>
        <% } %>
        <ul>
            <% if (emptyItem) { %>
            <li><a class="btn-accept" data-id="" href=""><%- emptyItem %></a></li>
            <% } %>
            <% _.each(objects, function(obj) { %>
            <li class="btn-accept" data-id="<%- obj.id %>"
                <% if (obj.color && colorEnabled) { %> style="background-color: <%= obj.color %>" <% } %>>
                <a href=""><%- obj.name %></a>
            </li>
            <% }); %>
        </ul>
    </div>
    """

    return (scope, element, attrs) ->
        # Do nothing if no model is specified
        return if not attrs.gmPopoverModel

        transformerName = attrs.gmPopoverModelTransformer or null
        transformer = transformers[transformerName] or (x) -> x

        # Hacky for reuse same attachPopover function
        attrs.gmPopover = attrs.gmGenericChoicePopover
        controller = new PopoverController($compile, $i18next, scope, element, attrs, template)

        scope.$watch attrs.gmPopoverModel, (data) ->
            return if data is undefined
            controller.initialize(transformer(data, scope))


GmUserChoicePopover = ($compile, $i18next) ->
    template = """
    <div class="<%- className %>">
        <p class="title" i18next="issues.select-user-popover">Select a user:</p>
        <ul>
            <% if (emptyItem) { %>
            <li><a class="btn-accept" data-id="" href=""><%- emptyItem %></a></li>
            <% } %>
            <% _.each(objects, function(obj) { %>
            <li>
                <a class="btn-accept" data-id="<%- obj.id %>"
                    gm-colorize-user="constants.users[<%- obj.id %>]" href=""><%- obj.name %></a>
            </li>
            <% }); %>
        </ul>
    </div>
    """
    return (scope, element, attrs) ->
        # Do nothing if no model is specified
        return if not attrs.gmPopoverModel

        transformerName = attrs.gmPopoverModelTransformer or null
        transformer = transformers[transformerName] or (x) -> x

        # Hacky for reuse same attachPopover function
        attrs.gmPopover = attrs.gmUserChoicePopover
        controller = new PopoverController($compile, $i18next, scope, element, attrs, template)

        scope.$watch attrs.gmPopoverModel, (data) ->
            return if data is undefined
            controller.initialize(transformer(data, scope))


GmGenericDialogPopover = ($compile, $i18next) ->
    template = """
    <div class="<%- className %>">
        <section>
            <p><%= title %></p>
        </section>
        <section>
            <input type="button" class="button button-success btn-accept" value="Delete"
                i18next="value:issues.delete-popover" />
            <input type="button" class="button button-delete btn-cancel"
                value="Cancel" i18next="value:issues.cancel-popover" />
        </section>
    </div>
    """

    return (scope, element, attrs) ->
        # Do nothing if no model is specified
        return if not attrs.gmPopoverModel

        # Hacky for reuse same attachPopover function
        attrs.gmPopover = attrs.gmGenericDialogPopover
        controller = new PopoverController($compile, $i18next, scope, element, attrs, template)

        scope.$watch attrs.gmPopoverModel, (data) ->
            return if data is undefined
            controller.initialize(data)


GmMarkdownPreviewPopover = ($compile, $i18next) ->
    template = """
    <div class="<%= className %>">
        <section class="btn-accept">
            <strong i18next="issues.blocking-reasons-popover"><?= title %></strong>
            <div gm-render-markdown="<%= model %>"></div>
        </section>
    </div>
    """

    return (scope, element, attrs) ->
        # Do nothing if no model is specified
        return if not attrs.gmPopoverModel

        # Hacky for reuse same attachPopover function
        attrs.gmPopover = attrs.gmGenericDialogPopover
        controller = new PopoverController($compile, $i18next, scope, element, attrs, template)

        scope.$watch attrs.gmPopoverModel, (data) ->
            return if data is undefined
            controller.initialize(data)

GmTemplatePopover = ($compile, $templateCache, $i18next) ->
    return (scope, element, attrs) ->
        # Do nothing if no model is specified
        return if not attrs.gmPopoverModel

        # Hacky for reuse same attachPopover function
        attrs.gmPopover = ""

        template = $templateCache.get(attrs.gmTemplatePopover)
        controller = new PopoverController($compile, $i18next, scope, element, attrs, template)

        scope.$watch attrs.gmPopoverModel, (data) ->
            return if data is undefined

            controller.initialize(data)

GmColorPickerPopover = ($compile, $i18next) ->
    template = """
    <div class="colorSelector"></div>
    """

    return (scope, element, attrs) ->
        # Hacky for reuse same attachPopover function
        attrs.gmPopover = attrs.gmColorPickerPopover

        controller = new ColorPickerPopoverControler($compile, $i18next, scope, element, attrs, template)
        controller.initialize({})


module = angular.module("taiga.directives.popovers", ["i18next"])
module.directive("gmGenericChoicePopover", ["$compile", "$i18next", GmGenericChoicePopover])
module.directive("gmUserChoicePopover", ["$compile", "$i18next", GmUserChoicePopover])
module.directive("gmGenericDialogPopover", ["$compile", "$i18next", GmGenericDialogPopover])
module.directive("gmMarkdownPreviewPopover", ["$compile", "$i18next", GmMarkdownPreviewPopover])
module.directive("gmColorPickerPopover", ["$compile", "$i18next", GmColorPickerPopover])
module.directive("gmTemplatePopover", ["$compile", "$templateCache", "$i18next", GmTemplatePopover])
