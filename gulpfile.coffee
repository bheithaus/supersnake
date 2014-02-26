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
client_base = './client/coffeescripts/'
path = 
  scripts: 
    src: {
      client:[
        client_base + '/**/*.coffee'
        client_base + '*.coffee'
      ]
      server: './**.coffee'
    }
    dest: './public/javascripts'

# Functions
scripts = () ->
  gulp.src(path.scripts.src.client)
    .pipe(coffee({ bare: true })).on('error', gutil.log)
    .pipe(concat('index.js'))
    .pipe(gulp.dest(path.scripts.dest))

gulp.task 'scripts', scripts

gulp.task 'default', ['scripts']


nodemon(
  script: 'app.coffee'
).on('restart', ->
  scripts()
)
