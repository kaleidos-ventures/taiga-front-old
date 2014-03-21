# an example karma.conf.coffee
module.exports = (config) ->
    config.set
        files : [
          "app/dist/libs.js",
          "app/components/angular-mocks/angular-mocks.js",
          "app/dist/app.js",
          "test/tests.js"
        ],
        basePath: '.'
        browsers: ['PhantomJS', 'Chrome']
        frameworks: ['jasmine']
