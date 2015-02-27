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
  known = args.parseKnown()
  stackerfile.load known['config']
  .spread (stackerfile, stacker) ->
    config.stackerfile = stackerfile
    config.stacker = stacker
    args.setConfig config.stacker
    log.setLevel config.stacker.logger?.level or 'info'
  .then ->
    # Check dependencies and load built-in tasks
    [
      dependencies.check()
      tasks.load path.resolve(__dirname, '../tasks/*')
    ]
  .all()
  .then ->
    # Load plugins and project tasks after built-in tasks have loaded
    [
      plugins.load()
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
  .catch (err) ->
    unless err == 'NOARGS'
      log.error err.message or err
      log.error err.stack
    args.printHelp()


loadProjectTasks = ->
  return []  unless config.stacker.tasks
  loaders = for pattern in config.stacker.tasks
    tasks.load path.resolve(process.cwd(), pattern)
  Promise.all loaders


module.exports =
  run: run
