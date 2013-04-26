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

    var applicationSources = [
	'app/js/app.js',
	'app/js/utils.js',
	'app/js/services/common.js',
	'app/js/services/resource.js',
	'app/js/services/storage.js',
	'app/js/controllers/auth.js',
	'app/js/controllers/project.js',
	'app/js/controllers/backlog.js',
	'app/js/controllers/dashboard.js',
	'app/js/controllers/issues.js',
	'app/js/controllers/wiki.js',
	'app/js/directives/generic.js',
	'app/js/directives/common.js',
	'app/js/directives/dashboard.js',
	'app/js/directives/issues.js',
	'app/js/directives/wiki.js',
	'app/js/filters/common.js'
    ];

    // Project configuration.
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        uglify: {
            options: {
                banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
            },
            app: {
                dest: "app/js/greenmine.min.js",
                src: applicationSources
            },
            libs: {
                dest: "app/js/extern.min.js",
                src: externalSources
            }
        },

        concat: {
            options: {
                separator: ';',
                banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                        '<%= grunt.template.today("yyyy-mm-dd") %> */\n'
            },

            appSources: {
                dest: "app/js/greenmine.min.js",
                src: applicationSources
            }
        },

        watch: {
            src: {
                files: applicationSources,
                tasks: ['concat:appSources']
            },
            less: {
                files: ['app/less/**/*.less'],
                tasks: ['less:development']
            }
        },

        jshint: {
            all: applicationSources
        },

        connect: {
            server: {
                options: {
                    port: 9001,
                    base: 'app'
                }
            }
        },

        less: {
            development: {
                options: {
                    paths: ["app/less"]
                },
                files: {
                    "app/less/style.css": "app/less/greenmine-main.less"
                }
            },
            production: {
                options: {
                    paths: ["app/less"],
                    yuicompress: true
                },
                files: {
                    "app/less/style.css": "app/less/greenmine-main.less"
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
        }
    });

    // Load the plugin that provides the "uglify" task.
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');

    // Default task(s).

    grunt.registerTask('production', [
        'less:production',
        'uglify',
        'htmlmin'
    ]);

    grunt.registerTask('development', [
        'concat:appSources',
        'less:development',
        'htmlmin',
    ]);

    grunt.registerTask('default', [
        'development',
        'connect',
        'watch'
    ]);
};
