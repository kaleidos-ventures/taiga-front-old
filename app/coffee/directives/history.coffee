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


GmHistoryRendererDirective = ($compile, rs) ->
    genericChangeTemplate = """
    <div class="change">
        <strong><%- field %></strong>:
        <span><%- oldValue %></span> ->
        <span><%- newValue %></span>
    </div>
    """

    htmlChangeTemplate = """
    <div class="change">
        <strong><%- field %></strong>:
        <span><%= oldValue %></span> ->
        <span><%= newValue %></span>
    </div>
    """

    pointsChangeTemplate = """
    <div class="change">
        <strong><%- field %></strong>:
        <% _.each(points, function(value, key) { %>
        <span>
            <strong><%- key %></strong>
            <span><%- value[0] %></span> ->
            <span><%- value[1] %></span>
        </span>
        <% }); %>
    </div>
    """

    itemTemplate = """
    <li class="history-item ng-scope">
        <div class="title">
            <span class="updated">
                <span i18next="user-story.updated-by-history">Updated by</span>
                <span gm-colorize-user="hitem.by"><%= changer %></span>
            </span>
            <span class="date ng-binding"><%= timeago %></span>
        </div>
        <div class="changes">
            <%= changes %>
        </div>
        <% if (comment) { %>
        <div class="comment"><%= comment %></div>
        <% } %>
    </li>
    """

    template = """
    <div class="history">
        <h3 i18next="common.history">History</h3>
        <div class="history-items-container">
            <div class="history-items"></div>
            <a class="more" data-icon="C" href="" i18next="common.see-more">See More</a>
        </div>
    </div>
    """

    page = 1
    hasNext = false
    historyItems = []

    ##########################################################
    ## Data loading functions
    ##########################################################

    _load = (type, pk, pagenum, scope, element, ctrl) ->
        params = {page: pagenum, page_size: 30}
        promise = rs.getHistory(type, pk, params)
        promise.then (data) ->
            hasNext = (data.next != null)
            historyItems = _.union(historyItems, data.results)
            return historyItems
        return promise

    initialize = (type, pk, scope, element, ctrl) ->
        page = 1
        historyItems = []
        return _load(type, pk, page, scope, element, ctrl)

    loadNextPage = (type, pk, scope, element, ctrl) ->
        page = page + 1
        return _load(type, pk, page, scope, element, ctrl)

    ##########################################################
    ## Tempates rendering functions
    ##########################################################

    translateFieldToName = (field) ->
        # TODO: use i18next in future
        return switch field
                   when "points" then "Points"
                   when "description_html" then "Description"
                   when "description_diff" then "Description diferences"
                   when "status" then "Status"
                   else field

    genericFieldToHtml = (field, changes) ->
        ctx = {
            oldValue: changes[0]
            newValue: changes[1]
            field: translateFieldToName(field)
        }

        if field == "description_html" or field == "content_html" or field == "description_diff"
            tmpl = _.template(htmlChangeTemplate)
        else
            tmpl = _.template(genericChangeTemplate)
        return tmpl(ctx)

    pointsFieldToHtml = (field, changes) ->
        ctx = {
            field: translateFieldToName(field)
            points: changes
        }

        tmpl = _.template(pointsChangeTemplate)
        return tmpl(ctx)

    historyItemToHtml = (item, element, ctrl) ->
        changes = []

        for field in _.keys(item.values_diff)
            if field == "description" or field == "content"
                continue
            value = item.values_diff[field]
            html = switch field
                       when "points" then pointsFieldToHtml(field, value)
                       else genericFieldToHtml(field, value)
            changes.push(html)

        tmpl = _.template(itemTemplate)
        ctx = {
            changes: changes.join("\n")
            changer: item.user.name
            timeago: moment(item.created_at).fromNow()
            comment: item.comment_html
        }
        return tmpl(ctx)

    # Transform loaded historyItems to html dom nodes
    # and put it visible in a main dom.
    render = (scope, element, ctrl) ->
        htmls = []

        for item in historyItems
            htmls.push(historyItemToHtml(item))

        domNodes = angular.element.parseHTML(htmls.join("\n"))
        domNodes = $compile(domNodes)(scope)

        dom = element.find(".history-items")
        dom.empty()
        dom.html(domNodes)

        if hasNext
            element.find("a.more").show()
        else
            element.find("a.more").hide()

    ##########################################################
    ## Events & Directive linking function
    ##########################################################

    link = (scope, element, attrs, ctrl) ->
        # Do nothing if history type is not defined
        if attrs.historyType is undefined
            return

        renderHistory = (pk) ->
            promise = initialize(attrs.historyType, pk, scope, element, attrs)
            promise.then ->
                render(scope, element, ctrl)

        scope.$watch attrs.objectId, (pk) ->
            if pk == null or pk == undefined
                return

            renderHistory(pk)

        scope.$on "history:reload", ->
            pk = scope.$eval(attrs.objectId)
            renderHistory(pk)

        element.on "$destroy", ->
            element.off(".history")

        element.on "click.history", "a.more", (event) ->
            pk = scope.$eval(attrs.objectId)
            promise = loadNextPage(attrs.historyType, pk, scope, element, attrs)
            promise.then ->
                render(scope, element, ctrl)

    return {
        link:link
        replace: true
        template: template
    }


module = angular.module("taiga.directives.history", ["i18next"])
module.directive("gmHistory", ["$compile", "resource", GmHistoryRendererDirective])
