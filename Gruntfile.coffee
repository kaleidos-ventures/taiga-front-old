module.exports = (grunt) ->
    externalSources = [
        'app/components/jquery/jquery.js',
        'app/components/jquery-ui/ui/jquery-ui.js',
        'app/components/markitup/markitup/jquery.markitup.js',
        'app/components/marked/lib/marked.js',
        'app/js/markdown.js',
        'app/components/lodash/dist/lodash.js',
        'app/components/lazy.js/lazy.js',
        'app/components/emoticons/lib/emoticons.js',
        'app/components/underscore.string/lib/underscore.string.js',
        'app/components/angular/angular.js',
        'app/components/angular-route/angular-route.js',
        'app/components/angular-sanitize/angular-sanitize.js',
        'app/components/angular-animate/angular-animate.js',
        'app/js/bootstrap.js',
        'app/components/moment/moment.js',
        'app/components/kalendae/build/kalendae.js',
        'app/components/checksley/checksley.js',
        'app/js/sha1.js',
        'app/js/cache.js',
        'app/components/jquery-flot/jquery.flot.js',
        'app/components/jquery-flot/jquery.flot.pie.js',
        'app/components/jquery-flot/jquery.flot.time.js',
        'app/js/jquery.flot.orderBars.js',
        'app/js/curvedLines.js',
        'app/js/emoticons-define.js',
        'app/components/select2/select2.js',
        'app/components/i18next/release/i18next-1.7.1.js',
        'app/js/coffeeColorPicker.js',
        'app/js/coffeeColorPicker.angular.js',
        'app/components/google-diff-match-patch-js/diff_match_patch_uncompressed.js',
        'app/components/jqueryui-touch-punch/jquery.ui.touch-punch.js',
        'app/js/highlight.pack.js',
        'app/js/jquery.textcomplete.js'
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
