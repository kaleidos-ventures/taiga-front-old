@WikiController = ($scope, $rootScope, $location, $routeParams, rs) ->
    $rootScope.pageSection = 'wiki'
    $rootScope.pageBreadcrumb = ["Project", "Wiki", $routeParams.slug]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.formOpened = false
    $scope.form = {}

    projectId = $rootScope.projectId
    slug = $routeParams.slug

    promise = rs.getWikiPage(projectId, slug)
    promise.then (page) ->
        $scope.page = page
        $scope.content = page.content

    promise.then null, ->
        $scope.formOpened = true

    $scope.savePage = ->
        if $scope.page is undefined
            content = $scope.content

            rs.createWikiPage(projectId, slug, content).then (page) ->
                $scope.page = page
                $scope.content = page.content
                $scope.formOpened = false

        else
            $scope.page.content = $scope.content
            $scope.page.save().then ->
                $scope.formOpened = false

    $scope.openEditForm = ->
        $scope.formOpened = true
        $scope.content = $scope.page.content

    $scope.discartCurrentChanges = ->
        $scope.formOpened = false
        $scope.content = $scope.page.content

@WikiController.$inject = ['$scope', '$rootScope', '$location', '$routeParams', 'resource']
