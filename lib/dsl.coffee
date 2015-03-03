# Stacker DSL
#
# The DSL is a superset of gulp functions with additional common helpers.
# DSL methods are injected into the global namespace of a command file.

gulp = require 'gulp'
path = require 'path'
cliargs = require './args'
{prettyPrintStackTrace} = require './stacktrace'

# globals
_ = require 'stacker/_'
config = require 'stacker/config'
log = require 'stacker/log'
ps = require('stacker/utils').ps
{Promise, co, isPromise, isGenerator} = require 'stacker/promise'


# Get task function arguments
#
# Examples:
#   getTaskArgs 'name', ['dep1', 'dep2'], desc: "help", ->
#   getTaskArgs 'name', desc: "help", ->
#   getTaskArgs 'name', ['dep1', 'dep2'], ->
#   getTaskArgs 'name', ->
getTaskArgs = (name, deps, opts, action) ->
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
  namespace = name.split(':')[0]
  [namespace, name, deps, opts, action]


# Inject DSL into a file
inject = (contents) ->
  # Add `yield` in front of async dsl methods
  yieldfor = YIELDFOR.join '|'
  re = ///^
    # Match if not a comment
    ([^\#]*?\s+)
    (#{yieldfor})
    \s
    (.+?)
  $///mg
  contents.replace re, '$1yield $2 $3'

  # OLD INJECTION METHOD
  # [
  #   "__stacker__ = {dsl: require('#{__filename}').dsl}"
  #   methods().join '\n'
  #   contents
  # ].join '\n'


# OLD INJECTION METHOD
# Returns array of DSL methods strings for injecting in a file
# cache = {}
# methods = ->
#   cache.methods ?=
#     "#{k} = __stacker__.dsl.#{k}" for k,v of DSL when k[0] is not '_'
#   cache.methods


# Add a task.
#
# Order of params is flexible. See getTaskArgs.
#
# In order for task dependencies to complete before a task is run, the dependencies
# need to provide async hints. This can happen by returning a stream or promise or
# calling the callback function passed into the action.
#
# Task is a wrapper around gulp.task which is an alias of
# [Orchestrator.add](https://github.com/orchestrator/orchestrator#orchestratoraddname-deps-function)
#
# @param name       Name of task
# @param deps       Array of dependent tasks to be run prior to running action
# @param opts       Options object
# @param action     Task function
task = (name, deps, opts, action) ->
  [namespace, name, deps, opts, action] = getTaskArgs.apply null, arguments
  cliargs.command name, opts
  action_wrapper = (cb) ->
    ret = action cb
    if _.isArray(ret) or isPromise(ret) or isGenerator(ret)
      ret
    else
      Promise.resolve ret
  sandbox = @
  gulp.task name, deps, (cb) ->
    co ->
      try
        ret = yield action_wrapper cb
        Promise.resolve ret
      catch err
        Promise.reject err
    .catch (err) ->
      err = prettyPrintStackTrace err,
        filename: sandbox.__filename
        source: sandbox.__source
        # Do not use sourceMap since stack is already correct if we've made it this far
        sourceMap: false
      log.error err.message or err
      log.error err.stack  if err.stack


# Run a shell command
sh = (cmd, opts = {}) ->
  ps.spawn 'sh', ['-c', cmd], opts


# Run a shell command as sudo
sudo = (cmd, opts = {}) ->
  ps.spawn 'sudo', ['sh', '-ci', cmd], opts


# Print header banner for CLI output
printHeader = (title, opts = {}) ->
  _.defaults opts,
    char: '='
    maxWidth: 80
    padding: [2, 1] # newlines before, after
  cols = process.stdout.columns
  cols = opts.maxWidth  if cols > opts.maxWidth
  len = stripAnsi(title).length
  cnt = Math.floor( (cols - len - 2) / 2 )
  dashes = new Array(cnt + 1).join opts.char
  str = "#{dashes} #{title} #{dashes}"
  str += opts.char  if str.length % 2 is 1
  padding = [
    new Array(opts.padding[0]+1).join "\n"
    new Array(opts.padding[1]+1).join "\n"
  ]
  process.stdout.write "#{padding[0]}#{str}\n#{padding[1]}"


# Strip ansi control characters
STRIP_ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g
stripAnsi = (str) ->
  str.replace STRIP_ANSI_REGEX, ''

cli =
  args: cliargs
  color: require 'chalk'
  printHeader: printHeader
  stripAnsi: stripAnsi

# Override gulp.inspect for debug output
gulp.inspect = (depth) ->
  src: gulp.src
  dest: gulp.dest
  task: gulp.task
  watch: gulp.watch

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
  cli: cli

module.exports =
  yieldfor: YIELDFOR
  dsl: DSL
  inject: inject
