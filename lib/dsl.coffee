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
Table = require 'cli-table'

_.isPromise = (obj) ->
  obj && 'function' == typeof obj.then
_.isGenerator = (obj) ->
  obj && 'function' == typeof obj.next && 'function' == typeof obj.throw




# getArgs
#
# Examples:
#   getArgs 'namespace', 'name', ['dep1', 'dep2'], desc: "help", ->
#   getArgs 'namespace', 'name', desc: "help", ->
#   getArgs 'namespace', 'name', ['dep1', 'dep2'], ->
#   getArgs 'namespace', 'name', ->
getArgs = (namespace, name, deps, opts, action) ->
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


# Add a task.
#
# Omit the namespace param when calling task as it's automatically injected by
# a task wrapper. Order of params is flexible. See getArgs.
#
# In order for task dependencies to complete before a task is run, the dependencies
# need to provide async hints. This can happen by returning a stream or promise or
# calling the callback function passed into the action.
#
# Task is a wrapper around
# [Orchestrator.add](https://github.com/orchestrator/orchestrator#orchestratoraddname-deps-function)
#
# @param namespace  Automatically added. See runner.inject
# @param name       Name of task
# @param deps       Array of dependent tasks to be run prior to running action
# @param opts       Options object
# @param action     Task function
task = (namespace, name, deps, opts, action) ->
  [task_name, deps, opts, action] = getArgs.apply null, arguments
  help.setHelp task_name, deps, opts  unless help.getHelp task_name
  action_wrapper = (cb) ->
    ret = action cb
    if _.isArray(ret) or _.isPromise(ret) or _.isGenerator(ret)
      ret
    else
      Promise.resolve ret
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


printHelp = ->
  table = new Table
    head: ['Command', 'Description']
    style:
      compact: true
  for name, h of help.getHelp()
    table.push [name, h.opts.desc or '']
  console.log table.toString()


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
  printHelp: printHelp

module.exports =
  yieldfor: YIELDFOR
  dsl: DSL
