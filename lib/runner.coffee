gulp = require 'gulp'
path = require 'path'

dsl = require('./dsl').dsl
tasks = require './tasks'
args = require './args'
stackerfile = require './stackerfile'
dependencies = require './dependencies'
plugins = require './plugins'

# global
log = require 'stacker/log'
config = require 'stacker/config'

run = ->
  stackerfile.load args.parseKnown()['config']
  .spread (stackerfile, stacker) ->
    config.stackerfile = stackerfile
    config.stacker = stacker
    args.setConfig config.stacker
    log.setLevel config.stacker.logger?.level or 'info'
  .then ->
    # Load plugins and task files
    # TODO: add caching here
    [
      plugins.load()
      tasks.load path.resolve(__dirname, '../tasks/*')
      loadProjectTasks()
    ]
  .all()
  .then ->
    # Parse task files
    # CLI help gets populated with tasks help
    tasks.parse()
  .then ->
    # Parse args now that cli help is fully populated
    args.parse()
    # Run task
    gulp.start args.get('task')

  .then ->
    # Debug SandboxModule require
    # Make sure things have not bled into this global context
    assert = require 'assert'
    assert !global.testtest, 'GLOBAL.TESTTEST SHOULD NOT BE DEFINED HERE'
    assert !String::to, 'STRING PROTOTYPE SHOULD NOT BE SET HERE'

  .catch (err) ->
    unless err is 'NOARGS' # TODO: write tests for NOARGS, not sure why this is here
      log.error err.message or err
      log.error err.stack  if err.stack
    unless err.code is 'TASKERROR'
      args.printHelp()


loadProjectTasks = ->
  return []  unless config.stacker.tasks
  loaders = for pattern in config.stacker.tasks
    tasks.load path.resolve(process.cwd(), pattern)
  Promise.all loaders


module.exports =
  run: run
