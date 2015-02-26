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
  stackerfile.load args.getConfig()
  .spread (stackerfile, stacker) ->
    config.stackerfile = stackerfile
    config.stacker = stacker
    # TODO: apply args here
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
  .then ->
    cmd = args.get 'task'
    throw 'NOARGS'  unless cmd
    gulp.start cmd
  .catch (err) ->
    log.error(err.message or err)  unless err == 'NOARGS'
    args.printHelp()


loadProjectTasks = ->
  return []  unless config.stacker.tasks?.files?
  loaders = for pattern in config.stacker.tasks.files
    tasks.load path.resolve(process.cwd(), pattern)
  Promise.all loaders


module.exports =
  run: run
