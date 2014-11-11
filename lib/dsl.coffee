# Stacker DSL
#
# The DSL is a superset of gulp functions with additional common helpers.
# DSL methods are injected into the global namespace of a command file.

gulp = require 'gulp'
_ = require 'lodash'
Promise = require 'bluebird'
path = require 'path'
co = require 'co'
log = require 'log'
ps = require 'stacker-utils/utils/ps'

help = require 'help'

NAMESPACE = ''


# Set the namespace for proceeding tasks
namespace = (name) ->
  NAMESPACE = name  if name?
  NAMESPACE

# getArgs
#
# Examples:
#   getArgs 'name', ['dep1', 'dep2'], desc: "help", ->
#   getArgs 'name', desc: "help", ->
#   getArgs 'name', ['dep1', 'dep2'], ->
#   getArgs 'name', ->
getArgs = (name, deps, opts, action) ->
  ns = namespace()
  args = Array.prototype.slice.call arguments, 0
  unless _.isArray deps
    deps = []
    deps = args[2]  if _.isArray args[2]
  unless typeof opts == 'object'
    opts = {}
    opts = args[1]  if _.isObject(args[1]) and not _.isArray(args[1]) and not _.isFunction(args[1])
  unless _.isFunction action
    if _.isFunction args[2]
      action = args[2]
    else if _.isFunction args[1]
      action = args[1]
  task_name = if ns and name
    "#{ns}:#{name}"
  else if name
    name
  else if ns
    ns
  else
    throw 'Invalid task name: namespace and task name cannot both be empty'
  [task_name, deps, opts, action]


# Add a task
task = (name, deps, opts, action) ->
  [task_name, deps, opts, action] = getArgs.apply null, arguments
  help.setHelp task_name, deps, opts  unless help.getHelp task_name
  action_wrapper = (cb) ->
    ret = action cb
    if _.isObject(ret) or _.isArray(ret)
      ret
    else
      Promise.resolve()
  gulp.task task_name, deps, (cb) ->
    new Promise (resolve, reject) ->
      co( ->
        try
          ret = yield action_wrapper cb
          resolve ret
        catch err
          reject err
      )()
    .catch (err) ->
      log.error err.message
      log.error err.stack


# Run a shell command
sh = (cmd, opts) ->
  ps.spawn 'sh', ['-c', cmd], opts


helpDSL = (name, deps, opts) ->
  help.setHelp.apply null, getArgs.apply null, arguments



# Stacker DSL
module.exports =
  log: log
  namespace: namespace
  task: task
  sh: sh
  help: helpDSL
  gulp: gulp
  src: gulp.src
  dest: gulp.dest
  watch: gulp.watch

