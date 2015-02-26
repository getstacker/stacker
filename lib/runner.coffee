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
  stackerfile.load args.getConfig()
  .spread (stackerfile, stacker) ->
    config.stackerfile = stackerfile
    config.stacker = stacker
    # TODO: apply args here
  .then ->
    # TODO: use tasks src from config.stacker if set
    tasks.load TASKS_SRC
  .then ->
    # Parse args now that task files have populated cli help
    args.parse()
  .then ->
    cmd = args.get 'task'
    throw 'NOARGS'  unless cmd
    gulp.start cmd
  .catch (err) ->
    log.error(err.message or err)  unless err == 'NOARGS'
    args.printHelp()


module.exports =
  run: run
