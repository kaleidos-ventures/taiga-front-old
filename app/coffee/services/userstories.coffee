_generateTagList = (stories) ->
    tagsDict = {}
    for story in stories
        for tag in story.tags
            tagsDict[tag] = if tagsDict[tag] is undefined then 1 else tagsDict[tag] + 1
    return ({name: tag, count: count} for tag, count of tagsDict)

class UnassignedUserStories
    constructor: (@service) ->
        @stories = []
        @tags = []

    fetch: (projectId) ->
        @service(parseInt(projectId, 10)).then (stories) =>
            stories = _.sortBy(_.filter(stories, {"project": projectId, milestone: null}), "order")
            @tags = _generateTagList(stories)
            @stories = stories

    conditionalFetch: (projectId, callback) ->
        if @stories.length == 0
            @fetch(projectId).then(callback)
        else
            callback(@stories)

    filterBy: (filter) ->
        return (story for story in @stories when filter(story))

    filterBySelectedTags: ->
        selectedTags = _(@tags).filter("selected").map("name").value()
        @filterBy (story) -> _.intersection(selectedTags, story.tags).length != 0

    getStoryFollowing: (story) ->
        stories = @filterBySelectedTags()
        stories = @stories if stories.length == 0
        for _story, i in stories
            if story.ref == _story.ref
                pos = i + 1
                return stories[pos % @stories.length]

    getStoryPreceding: (story) ->
        stories = @filterBySelectedTags()
        stories = @stories if stories.length == 0
        for _story, i in stories
            if story.ref == _story.ref
                pos = i - 1
                return if pos > 0 then stories[pos] else stories[@stories.length - 1]

UnassignedUserStoriesProvider = (resource) ->
    service = new UnassignedUserStories(resource.getUnassignedUserStories)
    return service

module = angular.module('taiga.services.userstories', [])
module.factory('UnassignedUserStories', ['resource', UnassignedUserStoriesProvider])
