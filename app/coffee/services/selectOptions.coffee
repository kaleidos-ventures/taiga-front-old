class SelectOptionsService extends TaigaBaseService
    @.$inject = ["$rootScope"]

    constructor: (@rootScope) ->
        super()

    colorizedTags: (option, container) ->
        hash = hex_sha1(option.text.trim().toLowerCase())
        color = hash
            .substring(0,6)
            .replace("8","0")
            .replace("9","1")
            .replace("a","2")
            .replace("b","3")
            .replace("c","4")
            .replace("d","5")
            .replace("e","6")
            .replace("f","7")

        container.parent().css("background", "##{color}")
        container.text(option.text)
        return

    member: (option, container) =>
        if option.id
            member = _.find(@rootScope.constants.users, {id: parseInt(option.id, 10)})
            # TODO: Make me more beautiful and elegant
            return "<span style=\"padding: 0px 5px;
                                  border-left: 15px solid #{member.color}\">#{member.full_name}</span>"
        return "<span>#{option.text}</span>"

module = angular.module("taiga.services.selectOptions", [])
module.service("selectOptions", SelectOptionsService)
