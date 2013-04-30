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
                dest: "app/dist/libs.js",
                src: externalSources
            },

            app: {
                dest: "app/dist/app.js",
                src: ["app/dist/_app.js"]
            }
        },

        coffee: {
            mainDevelopment: {
                options: {join: false},
                files: {"app/dist/app.js": ["app/coffee/**/*.coffee"]}
            },

            mainProduction: {
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

            coffeeMain: {
                files: ['app/coffee/**/*.coffee'],
                tasks: ['coffee:mainDevelopment']
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
    ]);

    grunt.registerTask('production', [
        'less',
        'coffee:mainProduction',
        'uglify',
        'htmlmin',
    ]);

    grunt.registerTask('development', [
        'less',
        'coffee:mainDevelopment',
        'concat:libs',
        'htmlmin',
    ]);

    grunt.registerTask('default', [
        'development',
        'connect:devserver',
        'watch'
    ]);
};
