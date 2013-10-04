ModalServiceFactory = ($rootScope, $q, $log) ->
    modals = {}
    service = {}

    service.register = (name, domId) ->
        $log.info "registering modal: #{name}"
        modals[name] = domId

    service.open = (name, ctx) ->
        dom = angular.element("##{modals[name]}")

        defered = $q.defer()

        ctrl = dom.controller()
        scp = dom.scope()
        ctrl.initialize(defered, ctx)
        return defered.promise

    service.close = (name) ->
        dom = angular.element("##{modals[name]}")

        ctrl = dom.controller()
        ctrl.delete()

    return service


ModalRegisterDirective = ($rootScope, $modal) ->
    return (scope, element, attrs) ->
        name = attrs.klModal
        domId = _.uniqueId("kl-modal-")

        element.attr("id", domId)
        $modal.register(name, domId)


module = angular.module("greenmine.plugins.modal", [])
module.factory("$modal", ["$rootScope", "$q", "$log", ModalServiceFactory])
module.directive("klModal", ["$rootScope", "$modal", ModalRegisterDirective])
