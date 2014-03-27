#describe '$favico', ->
#    beforeEach(module('favico'))
#
#    describe 'favico service', ->
#        it 'create a Favico object with defaults values', inject ($favico) ->
#            expect($favico._favico).to.be.null
#            $favico.newFavico()
#            expect($favico._favico).not.to.be.null
#
#        it 'is singleton', inject ($favico) ->
#            $favico.newFavico()
#            favicoA = $favico._favico
#            $favico.newFavico()
#            favicoB = $favico._favico
#            expect(favicoA).not.to.be.null
#            expect(favicoA).to.be.equal(favicoB)
#
#        it 'destroy', inject ($favico) ->
#            expect($favico._favico).to.be.null
#            $favico.newFavico()
#            expect($favico._favico).not.to.be.null
#            $favico.destroy()
#            expect($favico._favico).to.be.null
