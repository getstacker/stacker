gulp = require 'gulp'

dsl = require('./dsl').dsl
tasks = require './tasks'
args = require './args'
stackerfile = require './stackerfile'

# global
log = require 'stacker/log'
config = require 'stacker/config'

TASKS_SRC = '../**/**/tasks/*'

run = ->
  args.parse()
  stackerfile.load args.get('stackerfile')
  .then (stacker) ->
    config.stacker = stacker
    # TODO: apply args here
  .then ->
    # TODO: use tasks src from config.stacker if set
    tasks.load TASKS_SRC
  .then ->
    cmd = args.get 'command'
    throw 'NOARGS'  unless cmd
    gulp.start cmd
  .catch (err) ->
    log.error(err.message or err)  unless err == 'NOARGS'
    dsl.printHelp()


module.exports =
  run: run
