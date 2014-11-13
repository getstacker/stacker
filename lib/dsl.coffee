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



# getArgs
#
# Examples:
#   getArgs 'name', ['dep1', 'dep2'], desc: "help", ->
#   getArgs 'name', desc: "help", ->
#   getArgs 'name', ['dep1', 'dep2'], ->
#   getArgs 'name', ->
_getArgs = (namespace, name, deps, opts, action) ->
  args = Array.prototype.slice.call arguments, 0
  unless _.isArray deps
    deps = []
    deps = args[3]  if _.isArray args[3]
  unless typeof opts == 'object'
    opts = {}
    opts = args[2]  if _.isObject(args[2]) and not _.isArray(args[2]) and not _.isFunction(args[2])
  unless _.isFunction action
    if _.isFunction args[3]
      action = args[3]
    else if _.isFunction args[2]
      action = args[2]
  task_name = if namespace and name
    "#{namespace}:#{name}"
  else if name
    name
  else if namespace
    namespace
  else
    throw 'Invalid task name: namespace and task name cannot both be empty'
  [task_name, deps, opts, action]


# Add a task
task = (namespace, name, deps, opts, action) ->
  [task_name, deps, opts, action] = _getArgs.apply null, arguments
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
sh = (cmd, opts = {}) ->
  ps.spawn 'sh', ['-c', cmd], opts


# Run a shell command as sudo
sudo = (cmd, opts = {}) ->
  ps.spawn 'sudo', ['sh', '-ci', cmd], opts


# Add yield in front of these methods
YIELDFOR = ['sh', 'sudo']

# Stacker DSL
DSL =
  log: log
  task: task
  sh: sh
  sudo: sudo
  gulp: gulp
  src: gulp.src
  dest: gulp.dest
  watch: gulp.watch
  help: help


module.exports =
  yieldfor: YIELDFOR
  dsl: DSL
