# Stacker DSL
#
# The DSL is a superset of gulp functions with additional common helpers.
# DSL methods are injected into the global namespace of a command file.

gulp = require 'gulp'
path = require 'path'

# globals
_ = require 'stacker/_'
config = require 'stacker/config'
log = require 'stacker/log'
help = require 'stacker/help'
ps = require('stacker/utils').ps
{Promise, co, isPromise, isGenerator} = require 'stacker/promise'



# Get task function arguments
#
# Examples:
#   getTaskArgs 'namespace', 'name', ['dep1', 'dep2'], desc: "help", ->
#   getTaskArgs 'namespace', 'name', desc: "help", ->
#   getTaskArgs 'namespace', 'name', ['dep1', 'dep2'], ->
#   getTaskArgs 'namespace', 'name', ->
getTaskArgs = (namespace, name, deps, opts, action) ->
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
# a task wrapper. Order of params is flexible. See getTaskArgs.
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
  [task_name, deps, opts, action] = getTaskArgs.apply null, arguments
  help.setHelp task_name, deps, opts  unless help.getHelp task_name
  action_wrapper = (cb) ->
    ret = action cb
    if _.isArray(ret) or isPromise(ret) or isGenerator(ret)
      ret
    else
      Promise.resolve ret
  gulp.task task_name, deps, (cb) ->
    co ->
      try
        ret = yield action_wrapper cb
        Promise.resolve ret
      catch err
        Promise.reject err
    .catch (err) ->
      log.error err.message or err
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
  config: config
  log: log
  task: task
  sh: sh
  sudo: sudo
  gulp: gulp

module.exports =
  yieldfor: YIELDFOR
  dsl: DSL
