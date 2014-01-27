module.exports = (grunt) ->
    externalSources = [
        'app/js/jquery.js',
        'app/js/ui/jquery-ui.js',
        'app/js/jquery.markitup.js',
        'app/js/markdown.js',
        'app/js/lodash.js',
        'app/js/lazy.js',
        'app/js/underscore.string.js',
        'app/js/angular.js',
        'app/js/angular-route.js',
        'app/js/angular-sanitize.js',
        'app/js/angular-animate.js',
        'app/js/bootstrap.js',
        'app/js/moment.js',
        'app/js/kalendae.js',
        'app/js/checksley.js',
        'app/js/sha1.js',
        'app/js/cache.js',
        'app/js/jquery.flot.js',
        'app/js/jquery.flot.pie.js',
        'app/js/jquery.flot.time.js',
        'app/js/jquery.flot.orderBars.js',
        'app/js/curvedLines.js',
        'app/js/select2.js',
        'app/js/i18next.js',
        'app/js/coffeeColorPicker.js',
        'app/js/coffeeColorPicker.angular.js',
        'app/js/diff_match_patch.js'
    ]

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            development: {
                options: {
                    paths: ['app/less']
                },
                files: {
                    "app/less/style.css": "app/less/taiga-main.less"
                }
            }
        },
        uglify: {
            options: {
                banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
                mangle: true,
                report: 'min'
            },

            libs: {
                dest: "app/dist/libs.js",
                src: externalSources
            },

            app: {
                dest: "app/dist/app.js",
                src: ["app/dist/_app.js"]
            }
        },

        coffee: {
            dev: {
                options: {join: false},
                files: {
                    "app/dist/app.js": [
                        "app/coffee/**/*.coffee"
                        "app/coffee/*.coffee"
                    ]
                }
            },

            pro: {
                options: {join: false},
                files: {"app/dist/_app.js": ["app/coffee/**/*.coffee"]}
            }
        },

        concat: {
            options: {
                separator: ';',
                banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                        '<%= grunt.template.today("yyyy-mm-dd") %> */\n'
            },

            libs: {
                dest: "app/dist/libs.js",
                src: externalSources
            }
        },

        watch: {
            less: {
                files: ['app/less/**/*.less'],
                tasks: ['less']
            },

            coffee: {
                files: ['app/coffee/**/*.coffee'],
                tasks: ['coffee:dev']
            },

            libs: {
                files: externalSources,
                tasks: ["concat"],
            }
        },

        connect: {
            devserver: {
                options: {
                    port: 9001,
                    base: 'app'
                }
            },

            proserver: {
                options: {
                    port: 9001,
                    base: 'app',
                    keepalive: true
                }
            }
        },

        htmlmin: {
            dist: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true
                },
                files: {
                    'app/index.html': 'app/index.template.html'
                }
            }
        },
    })

    grunt.loadNpmTasks('grunt-contrib-uglify')
    grunt.loadNpmTasks('grunt-contrib-concat')
    grunt.loadNpmTasks('grunt-contrib-less')
    grunt.loadNpmTasks('grunt-contrib-watch')
    grunt.loadNpmTasks('grunt-contrib-connect')
    grunt.loadNpmTasks('grunt-contrib-jshint')
    grunt.loadNpmTasks('grunt-contrib-htmlmin')
    grunt.loadNpmTasks('grunt-contrib-coffee')

    grunt.registerTask('pro', [
        'less',
        'coffee:pro',
        'uglify',
        'htmlmin',
    ])

    grunt.registerTask('dev', [
        'less',
        'coffee:dev',
        'concat:libs',
        'htmlmin',
    ])

    grunt.registerTask('default', [
        'dev',
        'connect:devserver',
        'watch'
    ])
