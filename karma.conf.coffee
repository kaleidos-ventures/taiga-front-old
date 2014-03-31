# an example karma.conf.coffee
module.exports = (config) ->
    config.set
        basePath: '.'
        browsers: ['PhantomJS']
        frameworks: ['mocha', 'sinon', 'sinon-chai', 'chai', 'chai-as-promised']
        reporters: ['progress', 'coverage']
        preprocessors: {
            'app/dist/app.js': ['coverage']
        },
        coverageReporter: {
            type : 'lcov',
            dir : 'coverage/'
        }
