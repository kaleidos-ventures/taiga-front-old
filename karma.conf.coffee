# an example karma.conf.coffee
module.exports = (config) ->
    config.set
        basePath: '.'
        browsers: ['PhantomJS']
        frameworks: ['mocha', 'chai']
        reporters: ['progress', 'coverage']
        preprocessors: {
            'app/dist/app.js': ['coverage']
        },
        coverageReporter: {
            type : 'lcov',
            dir : 'coverage/'
        }
