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
        # Do nothing explicitly

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

class TaigaDetailPageController extends TaigaPageController
    loadProjectTags: ->
        @rs.getProjectTags(@scope.projectId).then (data) =>
            @projectTags = data

    getTagsList: =>
        @projectTags or []

    removeAttachment: (attachment) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then =>
            @scope.attachments = _.without(@scope.attachments, attachment)
            attachment.remove()

        return promise

    removeNewAttachment: (attachment) ->
        @scope.newAttachments = _.without(@scope.newAttachments, attachment)

    removeObject: (object) ->
        promise = @confirm.confirm(@i18next.t("common.are-you-sure"))
        promise.then =>
            object.remove().then =>
                @location.url(@onRemoveUrl)

    saveNewAttachments: ->
        if @scope.newAttachments.length == 0
            return null

        promises = []
        for attachment in @scope.newAttachments
            promise = @rs[@uploadAttachmentMethod](@scope.projectId, @scope[@objectIdAttribute], attachment)
            promise.then =>
                @scope.newAttachments = _.without(@scope.newAttachments, attachment)
            promises.push(promise)

        promise = @q.all(promises)
        promise.then =>
            gm.safeApply @scope, =>
                @loadAttachments()

        promise.then null, (data) =>
            @loadAttachments()
            @gmFlash.error(@i18next.t("common.upload-attachment-error"))

        return promise

    loadAttachments: ->
        @rs[@getAttachmentsMethod](@scope.projectId, @scope[@objectIdAttribute]).then (attachments) =>
            @scope.attachments = attachments

    loadHistorical: (page=1) ->
        @rs[@getHistoricalMethod](@scope[@objectIdAttribute], {page: page}).then (historical) =>
            if @scope.historical and page != 1
                historical.models = @scope.historical.models.concat(historical.models)

            @scope.showMoreHistoricaButton = historical.models.length < historical.count
            @scope.historical = historical

    loadMoreHistorical: ->
        page = if @scope.historical then @scope.historical.current + 1 else 1
        @loadHistorical(page=page)


@.TaigaBaseController = TaigaBaseController
@.TaigaPageController = TaigaPageController
@.TaigaDetailPageController = TaigaDetailPageController
@.TaigaBaseService = TaigaBaseService
@.ModalBaseController = ModalBaseController
