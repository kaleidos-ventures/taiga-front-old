overlayServiceFactory = ($rootScope, $q) ->
    class OverlayService
        constructor: ->
            console.log "OverlayService.constructor"

            @.el = angular.element("<div />", {"class": "overlay"})
            @.defered = $q.defer()

            _.bindAll(@)

        close: ->
            console.log "OverlayService.close"
            @.el.off()
            @.el.remove()

        open: ->
            console.log "OverlayService.open"
            self = @

            @.el.on "click", (event) ->
                $rootScope.$apply ->
                    self.close()
                    self.defered.resolve()

            body = angular.element("body")
            body.append(@.el)

            return @.defered.promise

    return -> new OverlayService()


module = angular.module("greenmine.services.overlay", [])
module.factory('$gmOverlay', ["$rootScope", "$q", overlayServiceFactory])
