describe 'gmOverlay', ->
    beforeEach(module('gmOverlay'))

    describe '$gmOverlay service', ->
        it 'should allow to open an overlay', inject ($gmOverlay) ->
            $gmOverlay.open()
            expect(angular.element('.overlay').length).to.be.equal(1)

        it 'should open only one overlay', inject ($gmOverlay) ->
            $gmOverlay.open()
            $gmOverlay.open()
            expect(angular.element('.overlay').length).to.be.equal(1)

        it 'should allow to close an overlay using javascript', inject ($gmOverlay) ->
            $gmOverlay.open()
            expect(angular.element('.overlay').length).to.be.equal(1)
            $gmOverlay.close()
            expect(angular.element('.overlay').length).to.be.equal(0)

        it 'should allow to close an overlay by clicking', inject ($gmOverlay) ->
            $gmOverlay.open()
            expect(angular.element('.overlay').length).to.be.equal(1)
            angular.element('body').find('.overlay').triggerHandler('click')
            expect(angular.element('.overlay').length).to.be.equal(0)
