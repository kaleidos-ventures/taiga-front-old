var gulp = require("gulp");
var coffee = require("gulp-coffee");
var concat = require("gulp-concat");
var uglify = require("gulp-uglify");
var connect = require("gulp-connect");
var less = require("gulp-less");
var coffeelint = require("gulp-coffeelint");
var recess = require("gulp-recess");
var jshint = require("gulp-jshint");
var karma = require("gulp-karma");
var gutil = require("gulp-util");
var template = require("gulp-template");

var externalSources = [
    "app/components/jquery/dist/jquery.js",
    //"app/components/jquery-ui/ui/jquery-ui.js",
    "app/components/Sortable/Sortable.js",
    "app/components/markitup/markitup/jquery.markitup.js",
    "app/components/marked/lib/marked.js",
    "app/components/lodash/dist/lodash.js",
    "app/components/lazy.js/lazy.js",
    "app/components/emoticons/lib/emoticons.js",
    "app/components/underscore.string/lib/underscore.string.js",
    "app/components/angular/angular.js",
    "app/components/angular-route/angular-route.js",
    "app/components/angular-sanitize/angular-sanitize.js",
    "app/components/angular-animate/angular-animate.js",
    "app/js/bootstrap.js",
    "app/components/moment/moment.js",
    "app/components/kalendae/build/kalendae.js",
    "app/components/checksley/checksley.js",
    "app/js/sha1.js",
    "app/components/jquery-flot/jquery.flot.js",
    "app/components/jquery-flot/jquery.flot.pie.js",
    "app/components/jquery-flot/jquery.flot.time.js",
    "app/components/flot-orderBars/js/jquery.flot.orderBars.js",
    "app/js/curvedLines.js",
    "app/js/emoticons-define.js",
    "app/components/select2/select2.js",
    "app/components/angular-ui-select2/src/select2.js",
    "app/components/i18next/i18next.js",
    "app/js/jquery.color.js",
    "app/js/coffeeColorPicker.js",
    "app/js/coffeeColorPicker.angular.js",
    "app/components/google-diff-match-patch-js/diff_match_patch_uncompressed.js",
    "app/components/jqueryui-touch-punch/jquery.ui.touch-punch.js",
    "app/js/highlight.pack.js",
    "app/components/jquery-textcomplete/jquery.textcomplete.js",
    "app/components/isMobile/isMobile.js",
    "app/components/favico.js/favico.js"
];

var coffeeSources = [
    "app/coffee/*.coffee",
    "app/coffee/**/*.coffee"
];

// define tasks here
gulp.task("default", ["dev", "watch", "connect"]);

gulp.task("dev", ["coffee", "less", "libs", "template"]);

gulp.task("pro", ["less", "template"], function() {
    gulp.src(coffeeSources)
        .pipe(coffee().on("error", gutil.log))
        .pipe(concat("app.js"))
        .pipe(uglify())
        .pipe(gulp.dest("app/dist/"));
    gulp.src(externalSources)
        .pipe(concat("libs.js"))
        .pipe(uglify())
        .pipe(gulp.dest("app/dist/"));
});

gulp.task("coffee", function() {
    gulp.src(coffeeSources)
        .pipe(coffee().on("error", gutil.log))
        .pipe(concat("app.js"))
        .pipe(gulp.dest("app/dist/"));
});

gulp.task("hint", function() {
    gulp.src(coffeeSources)
        .pipe(coffee().on("error", gutil.log))
        .pipe(jshint())
        .pipe(jshint.reporter("default"))
});

gulp.task("less", function() {
    gulp.src("app/less/taiga-main.less")
        .pipe(less().on("error", gutil.log))
        .pipe(concat("style.css"))
        .pipe(gulp.dest("app/less"));
});

gulp.task("libs", function() {
    gulp.src(externalSources)
        .pipe(concat("libs.js"))
        .pipe(gulp.dest("app/dist/"));
});

gulp.task("lint", function() {
    gulp.src(coffeeSources)
        .pipe(coffeelint("coffeelint.json"))
        .pipe(coffeelint.reporter())
    gulp.src("app/less/taiga-main.less")
        .pipe(recess({strictPropertyOrder: false}))
});

gulp.task("template", function() {
    gulp.src("app/index.template.html")
        .pipe(template({stamp: (new Date()).getTime()}))
        .pipe(concat("index.html"))
        .pipe(gulp.dest("app"));
});

gulp.task("build-tests", function() {
    gulp.src(["test/**/*.coffee"])
        .pipe(coffee({"bare": true}).on("error", gutil.log))
        .pipe(concat("tests.js"))
        .pipe(gulp.dest("test"));
});

gulp.task("test", ["coffee", "libs", "build-tests"], function() {
    gulp.src(["app/dist/libs.js", "app/dist/app.js", "test/tests.js"])
        .pipe(karma({configFile: "karma.conf.coffee", action: "run"}));
});

gulp.task("watch", function () {
    gulp.watch(["app/less/*.less", "app/less/**/*.less"], ["less"]);
    gulp.watch(externalSources, ["libs"]);
    gulp.watch(["app/coffee/*.coffee", "app/coffee/**/*.coffee"], ["coffee"]);
});

gulp.task("connect", connect.server({
    root: "app",
    port: 9001,
    livereload: false,
}));
