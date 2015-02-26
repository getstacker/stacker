lazypipe = require 'lazypipe'
debug = require 'gulp-debug'

srcFiles = '**/*.stack'

# parseConfigs = lazypipe()
#   .pipe debug verbose: true
  # .pipe dest 'dist'


# cli.args.command('config', help: 'Some help text for config cmd')
#   .addArgument ['-f', '--foo'],
#     help: 'foo3 bar3'
#     dest: 'foo'
#   .addArgument ['-e', '--env'],
#     help: 'set environment'
#     dest: 'environment'   # name of arg


task 'config', help: 'Test config file', ->
  # TODO: ACCESS CONFIG FROM HERE
  #log.debug 'config: ', config
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


task 'config:show', desc: 'Output processed config files to stdout', ->
  # src from pipe
  # output to stdout
  console.log 'hello from config:show'




# config/php.ini.stack

# #!stacker """
# output: etc/php.ini
# conf:
#   php:
#     mamx_mem: 1000
# type: ini
# """
# max_mem = <%- conf.php.max_mem %>

