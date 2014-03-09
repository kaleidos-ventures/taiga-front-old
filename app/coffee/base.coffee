class TaigaBase
    initialize: ->

class TaigaBaseController extends TaigaBase
    constructor: (@scope) ->
        # Attach current application injector.
        @.injector = angular.element(document).injector()

        # Call initialize method throught
        # application injector.
        @.injector.invoke(@.initialize, @)

        scope.$on("$destroy", _.bind(@.destroy))

    destroy: ->
        # Do nothing explicitly

    initialize: ->
        # Only demostrative console log.
        console.log("INITIALIZE BASE", arguments)

    @.prototype.initialize.$inject = ["$gmAuth", "$i18next"]

class TaigaBaseDirective extends TaigaBase

class TaigaBaseFilter extends TaigaBase

class TaigaBaseService extends TaigaBase

@.TaigaBaseController = TaigaBaseController
