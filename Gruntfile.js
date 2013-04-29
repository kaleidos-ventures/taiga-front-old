module.exports = function(grunt) {
    var externalSources = [
	'app/js/lib/jquery-2.0.0.js',
	'app/js/lib/ui/jquery.ui.core.js',
	'app/js/lib/ui/jquery.ui.position.js',
	'app/js/lib/ui/jquery.ui.widget.js',
	'app/js/lib/ui/jquery.ui.mouse.js',
	'app/js/lib/ui/jquery.ui.draggable.js',
	'app/js/lib/ui/jquery.ui.droppable.js',
	'app/js/lib/ui/jquery.ui.effect.js',
	'app/js/lib/ui/jquery.ui.effect-drop.js',
	'app/js/lib/ui/jquery.ui.effect-transfer.js',
	'app/js/lib/ui/jquery.ui.position.js',
	'app/js/lib/ui/jquery.ui.sortable.js',
	'app/js/lib/jquery.markitup.js',
	'app/js/lib/select2.js',
	'app/js/lib/markdown.js',
	'app/js/lib/lodash.js',
	'app/js/lib/underscore.string.js',
	'app/js/lib/angular.js',
	'app/js/lib/bootstrap.js',
	'app/js/lib/moment.js',
	'app/js/lib/kalendae.js',
	'app/js/lib/parsley.js',
	'app/js/lib/q.js',
	'app/js/lib/sha1.js',
	'app/js/lib/Chart.js'
    ];

    // Project configuration.
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        less: {
            dist: {
                options: {
                    paths: ["app/less"],
                    yuicompress: true
                },
                files: {
                    "app/less/style.css": "app/less/greenmine-main.less"
                }
            }
        },

        uglify: {
            options: {
                banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
                mangle: false,
                report: 'min'
            },

            libs: {
                dest: "app/dist/libs.min.js",
                src: [
                    "app/dist/libs.js",
                ]
            },

            app: {
                dest: "app/dist/app.min.js",
                src: [
                    'app/dist/app-main.js',
                    'app/dist/app-controllers.js',
                    'app/dist/app-directives.js',
                    'app/dist/app-services.js',
                    'app/dist/app-filters.js'
                ]
            }
        },

        coffee: {
            main: {
                options: {join: true},
                files: {"app/dist/app-main.js": ["app/coffee/*.coffee"]}
            },

            controllers: {
                options: {join: true},
                files: {
                    "app/dist/app-controllers.js": ["app/coffee/controllers/*.coffee"]
                }
            },

            directives: {
                options: {join: false},
                files: {
                    "app/dist/app-directives.js": ["app/coffee/directives/*.coffee"]
                }
            },

            services: {
                options: {join: false},
                files: {
                    "app/dist/app-services.js": ["app/coffee/services/*.coffee"]
                }
            },

            filters: {
                options: {join:  false},
                files: {
                    "app/dist/app-filters.js": ["app/coffee/filters/*.coffee"]
                }
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

            coffeeMain: {
                files: ['app/coffee/*.coffee'],
                tasks: ['coffee:main']
            },

            coffeeControllers: {
                files: "app/coffee/controllers/*.coffee",
                tasks: ['coffee:controllers']
            },

            coffeeServices: {
                files: "app/coffee/directives/*.coffee",
                tasks: ['coffee:services'],
            },

            coffeeDirectives: {
                files: "app/coffee/services/*.coffee",
                tasks: ['coffee:directives'],
            },

            coffeeFilters: {
                files: "app/coffee/filters/*.coffee",
                tasks: ['coffee:filters'],
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
            dev: {
                options: {
                    removeComments: false,
                    collapseWhitespace: false
                },
                files: {
                    'app/index.html': 'app/index.template.dev.html'
                }
            },
            dist: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true
                },
                files: {
                    'app/index.html': 'app/index.template.pro.html'
                }
            }
        },
    });

    // Load the plugin that provides the "uglify" task.
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');
    grunt.loadNpmTasks('grunt-contrib-coffee');

    grunt.registerTask('generic', [
        'concat:libs',
        'coffee',
        'less'
    ]);

    grunt.registerTask('production', [
        'generic',
        'uglify',
        'htmlmin:dist',
    ]);

    grunt.registerTask('development', [
        'generic',
        'htmlmin:dev',
    ]);

    grunt.registerTask('default', [
        'development',
        'connect:devserver',
        'watch'
    ]);
};
