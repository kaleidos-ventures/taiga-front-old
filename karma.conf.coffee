# an example karma.conf.coffee
module.exports = (config) ->
    config.set
        basePath: '.'
        simgleRun: true
        browsers: ['PhantomJS']
        frameworks: ['jasmine']
