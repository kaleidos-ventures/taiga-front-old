describe 'filter', ->
    beforeEach(module('taiga.filters'))
    describe 'onlyVisible', ->
        it('should filter objects __hidden field equals to true', inject((onlyVisibleFilter) ->
            objects = [
                { id: "test1", __hidden: true }
                { id: "test2", __hidden: false }
                { id: "test3", __hidden: true }
                { id: "test4" }
            ]
            expectedObjects = [
                { id: "test2", __hidden: false }
                { id: "test4" }
            ]

            expect(onlyVisibleFilter(objects)).to.be.deep.equal(expectedObjects)
        ))

    describe 'truncate', ->
        it('should truncate a word', inject((truncateFilter) ->
            expect(truncateFilter('test of truncation', 20)).to.be.equal('test of truncation')
            expect(truncateFilter('test of truncation', 10)).to.be.equal('test of...')
            expect(truncateFilter('test of truncation with default value')).to.be.equal('test of truncation with...')
        ))

    describe 'slugify', ->
        it('should convert a string in a slug', inject((slugifyFilter) ->
            expect(slugifyFilter('test')).to.be.equal('test')
            expect(slugifyFilter('Test')).to.be.equal('test')
            expect(slugifyFilter('test two')).to.be.equal('test-two')
            expect(slugifyFilter('test_three')).to.be.equal('test-three')
            expect(slugifyFilter('testñfour')).to.be.equal('testnfour')
        ))

    describe 'momentFormat', ->
        it "should format a date", inject (momentFormatFilter) ->
            date = "2013-02-08T09:30:26+00:00"
            expect(momentFormatFilter(date, "DD-MM-YYYY")).to.be.equal("08-02-2013")

        it "should return the same", inject (momentFormatFilter) ->
            # TODO: Fix problems with UTC between local and TravisCI Server
            #date = "2013-02-08T09:30:26+00:00"
            #expect(momentFormatFilter(date, "")).to.be.equal(result)
            #expect(momentFormatFilter(date, null)).to.be.equal(result)
            #expect(momentFormatFilter(date, undefined)).to.be.equal(result)

        it "should return nothing", inject (momentFormatFilter) ->
            expect(momentFormatFilter(null)).to.be.equal("")
            expect(momentFormatFilter(undefined)).to.be.equal("")
            expect(momentFormatFilter("")).to.be.equal("")
            expect(momentFormatFilter("", "")).to.be.equal("")
            expect(momentFormatFilter("", null)).to.be.equal("")
            expect(momentFormatFilter("", undefined)).to.be.equal("")

    describe 'lowercase', ->
        it('should change the case to all lower case', inject((lowercaseFilter) ->
            expect(lowercaseFilter('TAIGA')).to.be.equal('taiga')
            expect(lowercaseFilter('Taiga')).to.be.equal('taiga')
            expect(lowercaseFilter('taiga')).to.be.equal('taiga')
            expect(lowercaseFilter('TaIgA')).to.be.equal('taiga')
            expect(lowercaseFilter()).to.be.equal('')
        ))

    describe 'capitalize', ->
        it('should change the case to capitalize case', inject((capitalizeFilter) ->
            expect(capitalizeFilter('TAIGA')).to.be.equal('Taiga')
            expect(capitalizeFilter('Taiga')).to.be.equal('Taiga')
            expect(capitalizeFilter('taiga')).to.be.equal('Taiga')
            expect(capitalizeFilter('TaIgA')).to.be.equal('Taiga')
            expect(capitalizeFilter('')).to.be.equal('')
        ))

    describe 'sizeFormat', ->
        it('should return the size in human readable format', inject((sizeFormatFilter) ->
            expect(sizeFormatFilter(1000, 1)).to.be.equal('1000.0 bytes')
            expect(sizeFormatFilter(1000)).to.be.equal('1000.0 bytes')
            expect(sizeFormatFilter(1024)).to.be.equal('1.0 KB')
            expect(sizeFormatFilter(1024*1024)).to.be.equal('1.0 MB')
            expect(sizeFormatFilter(1024*1024*1024)).to.be.equal('1.0 GB')
            expect(sizeFormatFilter(1024*1024*1024*1024)).to.be.equal('1.0 TB')
            expect(sizeFormatFilter(1024*1024*1024*1024*1024)).to.be.equal('1.0 PB')
            expect(sizeFormatFilter(1024*1024*1024*1024*1024*1024)).to.be.equal('1024.0 PB')

            expect(sizeFormatFilter(2*1024*1024+10)).to.be.equal('2.0 MB')

            expect(sizeFormatFilter(Math.Inf)).to.be.equal('-')
            expect(sizeFormatFilter(0)).to.be.equal('0 bytes')
        ))

    describe 'diff', ->
        it 'should return the same text', inject (diffFilter, $sce) ->
            expect($sce.getTrustedHtml(diffFilter("Sample text", "Sample text"))).to.be.equal(
                                                                    "<span>Sample text</span>")

        it 'should marks the added text', inject (diffFilter, $sce) ->
            expect($sce.getTrustedHtml(diffFilter("Sample text with extra text", "Sample text"))).to.be.equal(
                           "<span>Sample text</span><ins style=\"background:#e6ffe6;\"> with extra text</ins>")

        it 'should marks the deleted text', inject (diffFilter, $sce) ->
            expect($sce.getTrustedHtml(diffFilter("Sample text", "Sample text with extra text"))).to.be.equal(
                           "<span>Sample text</span><del style=\"background:#ffe6e6;\"> with extra text</del>")

        it 'should allow to disable semantic diff', inject (diffFilter, $sce) ->
            expect($sce.getTrustedHtml(diffFilter("Sample text", "Sample text with extra text", false))).to.be.equal(
                           "<span>Sample text</span><del style=\"background:#ffe6e6;\"> with extra text</del>")

        it 'should allow to enable efficiency on diff', inject (diffFilter, $sce) ->
            expect($sce.getTrustedHtml(diffFilter("Sample text", "Sample text with extra text", null, true))).to.be.equal(
                           "<span>Sample text</span><del style=\"background:#ffe6e6;\"> with extra text</del>")
