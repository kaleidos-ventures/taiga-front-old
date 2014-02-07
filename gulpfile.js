var gulp = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');
var connect = require('gulp-connect');
var less = require('gulp-less');
var coffeelint = require('gulp-coffeelint');
var recess = require('gulp-recess');

var externalSources = [
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
];

var coffeeSources = [
    'app/coffee/**/*.coffee',
    'app/coffee/*.coffee'
];

// define tasks here
gulp.task('default', ['dev', 'watch', 'connect']);

gulp.task('dev', ['coffee', 'less', 'libs']);

gulp.task('pro', ['coffee', 'less', 'libs'], function() {
    gulp.src('app/dist/app.js')
        .pipe(uglify())
        .pipe(gulp.dest('app/dist/'));
    gulp.src('app/dist/libs.js')
        .pipe(uglify())
        .pipe(gulp.dest('app/dist/'));
});

gulp.task('coffee', function() {
    gulp.src(coffeeSources)
        .pipe(coffee())
        .pipe(concat('app.js'))
        .pipe(gulp.dest('app/dist/'));
});

gulp.task('less', function() {
    gulp.src('app/less/taiga-main.less')
        .pipe(less())
        .pipe(concat('style.css'))
        .pipe(gulp.dest('app/less'));
});

gulp.task('libs', function() {
    gulp.src(externalSources)
        .pipe(concat('libs.js'))
        .pipe(gulp.dest('app/dist/'));
});

gulp.task('lint', function() {
    gulp.src(coffeeSources)
        .pipe(coffeelint('coffeelint.json'))
        .pipe(coffeelint.reporter())
    gulp.src('app/less/taiga-main.less')
        .pipe(recess({strictPropertyOrder: false}))
});

gulp.task('watch', function () {
    gulp.watch(['app/less/*.less', 'app/less/**/*.less', 'app/less/**/*.css'], ['less']);
    gulp.watch(externalSources, ['libs']);
    gulp.watch(['app/coffee/*.coffee', 'app/coffee/**/*.coffee'], ['coffee']);
});

gulp.task('connect', connect.server({
    root: 'app',
    port: 9001,
    livereload: true,
}));
