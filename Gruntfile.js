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
	'app/js/lib/spin.js',
	'app/js/lib/sha1.js',
	'app/js/lib/Chart.js',
	'app/js/lib/noty/jquery.noty.js',
	'app/js/lib/noty/default.js',
	'app/js/lib/noty/layout.js'
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

            dist: {
                dest: "app/dist/greenmine.min.js",
                src: [
                    "app/dist/libs.js",
                    "app/dist/app.js",
                ]
            }
        },

        coffee: {
            compile: {
                options: {join:  false},
                files: {
                    "app/dist/config.js": "app/coffee/config.coffee",
                    "app/dist/app.js": [
                        "app/coffee/app.coffee",
                        "app/coffee/utils.coffee",
                        "app/coffee/controllers/*.coffee",
                        "app/coffee/directives/*.coffee",
                        "app/coffee/services/*.coffee",
                        "app/coffee/filters/*.coffee"
                    ]
                }
            }
        },

        watch: {
            less: {
                files: ['app/less/**/*.less'],
                tasks: ['less']
            },

            coffee: {
                files: ['app/coffee/**/*.coffee'],
                tasks: ['coffee:compile']
            }
        },

        concat: {
            options: {
                separator: '\n;',
                banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                        '<%= grunt.template.today("yyyy-mm-dd") %> */\n'
            },

            libs: {
                dest: "app/dist/libs.js",
                src: externalSources
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

    // Default task(s).

    grunt.registerTask('production', [
        'concat:libs',
        'coffee:compile',
        'uglify:dist',
        'htmlmin:dist',
    ]);

    grunt.registerTask('development', [
        'concat:libs',
        'coffee:compile',
        'htmlmin:dev',
    ]);

    grunt.registerTask('default', [
        'development',
        'connect:devserver',
        'watch'
    ]);
};
