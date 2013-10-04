# #####################
# Confirm modal service
# #####################
#
# Simple way to launch confirmation modal before
# make a dangerous action.
#
# How it works?
# -------------
#
# As first, add $confirm service to yout $inject list
# of controller.
#
# $confirm service accepts js plain object as parameter with
# a lot of costumizacion to the generic modal:
#
# - title:      Setup a distinct title than generic
# - body:       Setup a body for the confirmation message. By default
#               is empty. On this parameter you can pass string or selector
#               to the <script /> template (that will be complied with same
#               scope as the modal. If you need put more variables to scope
#               use **scope** parameter)
# - scope:      Add more variables to the isolate scope of the modal.
# - btnOk:      Text for "OK" button (default "ok")
# - btnCancel:  Text for "CANCEL" button (default "cancel")
#
# Returns a promise that is resolved in case of user clicks to "ok" button
# or rejected in other case.
#
# Example
# ~~~~~~~
#
# $scope.remove ->
#     promise = promise$confirm.confirm(title:"Are you sure?")
#     promise.then ->
#         console.log "user clicks ok"
#     promise.then null, ->
#         console.log "user clicks cancel"

template = """
<div class="delete-provider salubox">
    <div class="head">
        <p class="title">{{ title }}</p>
        <a class="close" href="">
            <span sr="icon.close" class="ico" ></span>
        </a>
    </div>
    <div class="body">
        <div class="body-content">
            <p i18next="app.remove-provider-warning"></p>
            <p class="provider-name">{{provider.name}}</p>
        </div>
        <p i18next="app.are-you-sure"></p>
    </div>
    <div class="options clearfix">
        <a class="btn" ng-click="ok()" href="" title="{{ btnOk }}">{{ btnOk }}</a>
        <a class="btn cancel" ng-click="cancel()" href="">{{ btnCancel }}</a>
    </div>
</div>
"""


ConfirmProvider = ($rootScope, $q, $compile) ->
    service = {}
    scope = null
    modal = null

    format = (message, args) ->
        args = [args] if not _.isArray(args)
        return message.replace /%s/g, (match) ->
            return String(args.shift())

    translate = (text, params={}) ->
        if _.isString(text) and /^(app|confirm)\..*/i.test(text)
            return $rootScope.t(text, params)
        return text

    initializeOptions = (scope, options) ->
        scope.title = translate(options.title) or translate("app.are-you-sure")
        scope.btnOk = translate(options.btnOk) or translate("app.ok")
        scope.btnCancel = translate(options.btnCancel) or translate("app.cancel")
        scope.subject = translate(options.subject) or translate("app.are-you-sure")

        if _.isPlainObject(options.scope)
            for key, value of options.scope
                scope[key] = value

        if _.isString(options.body)
            if /^#/i.test(options.body)
                options.body = angular.element(options.body)
                $compile(options.body)(scope)
        else
            options.body = ""

    initializeOverlay = (callback) ->
        body = angular.element("body")

        overlay = angular.element("<div />", {"class": "overlay"})
        overlay.on "click", (event) ->
            scope.$apply ->
                callback(false)

        body.find(".header, .content").append(overlay)

    initializeModal = (scope, options, callback) ->
        scope.ok = ->
            callback(true)
        scope.cancel = ->
            callback(false)

        tmpl = angular.element("#confirm-dialog").html()
        modal = angular.element($.parseHTML(tmpl.trim()))
        modal.attr("id", _.uniqueId("confirm-"))

        modal.find(".body-content").empty()
        modal.find(".body-content").html(options.body)

        body = angular.element("body")
        body.append(modal)

        # Compile a modal dom with
        # new isolate created scope
        $compile(modal)(scope)

        # Sizing
        windowWidth = $(window).width() / 2
        modalWidth = modal.width() / 2
        modalPos = windowWidth - modalWidth
        modal.css('left', modalPos)
        modal.fadeIn('slow')

    closeOverlay = ->
        body = angular.element("body")
        body.find(".overlay").remove()

    destroyScope = ->
        if scope != null
            scope.$destroy()
            scope = null

    destroyDom = ->
        if modal != null
            modal.remove()
            modal = null

    manage = (defered) ->
        return (ok) ->
            closeOverlay()
            destroyScope()
            destroyDom()

            if ok
                defered.resolve()
            else
                defered.reject()

    service.confirm = (options={}) ->
        defered = $q.defer()

        scope = $rootScope.$new(true)
        initializeOptions(scope, options)

        initializeOverlay(manage(defered))
        initializeModal(scope, options, manage(defered))

        return defered.promise

    return service


SimpleConfirmProvider = ($rootScope, $q, $window) ->
    service = {}
    service.confirm = (message) ->
        defered = $q.defer()

        _.defer ->
            res = $window.confirm(message)
            if res
                defered.resolve()
            else
                defered.reject()
            $rootScope.$apply()

        return defered.promise
    return service


module = angular.module('greenmine.plugins.confirm', [])
#module.factory('$confirm', ["$rootScope", "$q", "$compile", ConfirmProvider])
module.factory('$confirm', ["$rootScope", "$q", "$window", SimpleConfirmProvider])
