UnassignedUserStoriesProvider = (resource) ->
    return {}

module = angular.module('taiga.services.userstories', [])
module.factory('UnassignedUserStories', ['resource', UnassignedUserStoriesProvider])
