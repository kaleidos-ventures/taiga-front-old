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
    debounceMethods: ->
        submit = @submit
        @submit = gm.utils.safeDebounced @scope, 500, submit

    initialize: ->
        @debounceMethods()
        @scope.formOpened = false

        # Load data
        @scope.defered = null
        @scope.context = null

    closeModal: ->
        @scope.formOpened = false

    start: (dfr, ctx) ->
        @scope.defered = dfr
        @scope.context = ctx
        @openModal()

    delete: ->
        @closeModal()
        @scope.form = form
        @scope.formOpened = true

    close: ->
        @scope.formOpened = false
        @gmOverlay.close()

        if @scope.form.id?
            @scope.form.revert()
        else
            @scope.form = {}

class TaigaPageController extends TaigaBaseController
    constructor: (scope, rootScope, favico) ->
        favico.reset()
        rootScope.pageSection = @.section
        rootScope.pageTitle = @.getTitle()
        super(scope)

@.TaigaBaseController = TaigaBaseController
@.TaigaPageController = TaigaPageController
@.TaigaBaseService = TaigaBaseService
@.ModalBaseController = ModalBaseController
