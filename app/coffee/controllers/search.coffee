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


class SearchController extends TaigaPageController
    @.$inject = ["$scope", "$rootScope", "$routeParams", "$data", "resource",
                 "$i18next", "$favico"]
    constructor: (@scope, @rootScope, @routeParams, @data, @rs, @i18next, @favico) ->
        super(scope, rootScope, favico)

    section: 'search'
    getTitle: ->
        @i18next.t("common.search")

    initialize: ->
        @rootScope.pageBreadcrumb = [
            ["", ""]
            [@i18next.t("common.search"), null]
        ]

        @scope.term = @routeParams.term

        @scope.resultTypeMap = {
            userstories: "User Stories"
            tasks: "Tasks"
            issues: "Issues"
            wikipages: "Wiki Pages"
        }

        @rs.resolve(pslug: @routeParams.pslug).then (data) =>
            @rootScope.projectSlug = @routeParams.pslug
            @rootScope.projectId = data.project
            @data.loadProject(@scope)

            @rs.search(@rootScope.projectId, @routeParams.term, false).then (results) =>
                @scope.results = results
                @scope.resultTypes = _.reject(_.keys(@scope.results), (x) -> x == "count")

                @scope.activeType = null
                maxItemsCounter = 0

                for type in @scope.resultTypes
                    if @scope.results[type].length > maxItemsCounter
                        @scope.activeType = type
                        maxItemsCounter = @scope.results[type].length

    translateResultType: (type) ->
        if @scope.resultTypeMap[type] == undefined
            return type
        return @scope.resultTypeMap[type]

    translateTypeUrl: (type, projectSlug, item) ->
        return switch type
            when "userstories" then @rootScope.urls.userStoryUrl(projectSlug, item.ref)
            when "tasks" then @rootScope.urls.tasksUrl(projectSlug, item.ref)
            when "issues" then @rootScope.urls.issuesUrl(projectSlug, item.ref)
            when "wikipages" then @rootScope.urls.wikiUrl(projectSlug, item.slug)
            else ""

    translateTypeTitle: (type, item) ->
        return switch type
            when "userstories" then item.subject
            when "tasks" then item.subject
            when "issues" then item.subject
            when "wikipages" then item.slug
            else ""

    translateTypeDescription: (type, item) ->
        return switch type
            when "userstories" then item.description
            when "tasks" then item.description
            when "issues" then item.description
            when "wikipages" then item.content
            else ""

    isTypeActive: (type) ->
        return type == @scope.activeType

    setActiveType: (type) ->
        @scope.activeType = type

moduleDeps = ["taiga.services.data", "taiga.services.resource", "i18next", "favico"]
module = angular.module("taiga.controllers.search", moduleDeps)
module.controller("SearchController", SearchController)
