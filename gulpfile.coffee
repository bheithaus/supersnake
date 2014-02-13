includeG = (module) -> 
  require 'gulp-' + module

# Requires
gulp = require 'gulp'
nodemon = require 'nodemon'
jade = includeG 'jade'
coffee = includeG 'coffee'
concat = includeG 'concat'
uglify = includeG 'uglify'
gutil = includeG 'util'
concat = includeG 'concat'


# Paths
path = 
  scripts: 
    src: {
      client: './client/coffeescripts/*.coffee'
      server: './**.coffee'
    }
    dest: './public/javascripts'

# Functions
scripts = () ->
  gulp.src(path.scripts.src.client)
    .pipe(coffee({ bare: true })).on('error', gutil.log)
    .pipe(concat('index.js'))
    .pipe(gulp.dest(path.scripts.dest))

# Tasks
gulp.task 'jade', ->
  gulp.src './views/*.jade'
    .pipe(jade())
    .pipe(gulp.dest('./build/minified_templates'))

gulp.task 'scripts', scripts

gulp.task 'watch', ->
  gulp.watch(path.scripts.src, ['scripts'])

gulp.task 'default', ['jade', 'scripts']


nodemon(
  script: 'app.coffee'
).on('restart', ->
  scripts()
)
