lazypipe = require 'lazypipe'
debug = require 'gulp-debug'

namespace 'config'
srcFiles = '**/*.stack'

# parseConfigs = lazypipe()
#   .pipe debug verbose: true
  # .pipe dest 'dist'

# TODO !!!!!!!
# 1. Add proper args/help support to task files
#    - not sure yet of best way to handle this
# 2. Add debug tasks to show config, dsl, etc. Introspection stuff.
# 3. Start wiring up stacker.json to load modules, etc.

# Default
task '', desc: 'Process config files', ->
  # TODO: ACCESS CONFIG FROM HERE
  log.debug 'config: ', config
  log.info 'hi!'
  ret = sh 'echo "hi [2] from sh" && sleep 1'
  console.log 'this should be after echo'
  log.info ret

  return

  gulp.src srcFiles
  .pipe debug verbose: true

  # .pipe parseConfigs
  # .pipe (file) ->
  #   #process the file
  # .pipe dest 'config'

  # gulp.src conf.gzipFiles
  # .pipe gulp.dest conf.dist
  # src '*.stack'
  # .pipe dest '/config'

  # log.info 'start of config >>>'
  # # should not process sh some command
  # ret = sudo 'cat root.test'
  # ret = sudo 'echo hi from sudo'

  # log.info '<<< end of config'


task 'show', desc: 'Output processed config files to stdout', ->
  # src from pipe
  # output to stdout
  console.log 'hello from config:show'

task 'debug', desc: 'Show debug output', ->



# config/php.ini.stack

# #!stacker """
# output: etc/php.ini
# conf:
#   php:
#     mamx_mem: 1000
# type: ini
# """
# max_mem = <%- conf.php.max_mem %>

