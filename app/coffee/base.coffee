class TaigaBase

class TaigaBaseController extends TaigaBase
    constructor: (@scope) ->
        # Attach current application injector.
        @.injector = angular.element(document).injector()

        # Call initialize method throught.
        @.initialize()

        _.bindAll(@)
        scope.$on("$destroy", @.destroy)

    destroy: ->
        # Do nothing explicitly

    initialize: ->
        # Only demostrative console log.
        console.log("INITIALIZE BASE", arguments)

class TaigaBaseDirective extends TaigaBase

class TaigaBaseFilter extends TaigaBase

class TaigaBaseService extends TaigaBase

class ModalBaseController extends TaigaBaseController

@.TaigaBaseController = TaigaBaseController
@.ModalBaseController = ModalBaseController
