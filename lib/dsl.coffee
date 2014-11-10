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


# Set the namespace for proceeding tasks
namespace = (name) ->
  stacker.NAMESPACE = name  if name?
  stacker.NAMESPACE


help = (name, deps, opts) ->
  setHelp.apply @, getArgs.apply @, arguments

getHelp = (task_name) ->
  stacker.help[task_name]

setHelp = (task_name, deps, opts) ->
  stacker.help[task_name] =
    deps: deps
    opts: opts
    file: path.resolve __dirname, require.main.filename


getArgs = (name, deps, opts, action) ->
  ns = namespace()
  args = Array.prototype.slice.call arguments, 0
  deps = findParam args, 'Array'
  opts = findParam args, 'Object'
  action = findParam args, 'Function'
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
  [task_name, deps, opts, action] = getArgs.apply @, arguments
  setHelp task_name, deps, opts  unless getHelp task_name
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


findParam = (params, type) ->
  for p, i in params
    return p  if _["is#{type}"] p
  new global[type]


# Stacker DSL
module.exports =
  stacker:
    NAMESPACE: ''
    help: {}
  log: log
  namespace: namespace
  task: task
  sh: sh
  help: help
  gulp: gulp
  src: gulp.src
  dest: gulp.dest
  watch: gulp.watch
