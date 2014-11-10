# Stacker DSL
#
# The DSL is a superset of gulp functions with additional common helpers.
# DSL methods are injected into the global namespace of a command file.

gulp = require 'gulp'
_ = require 'lodash'
Promise = require 'bluebird'
co = require 'co'
log = require 'log'
ps = require 'stacker-utils/utils/ps'


# Set the namespace for proceeding tasks
namespace = (name) ->
  # plugin = path.basename(opts.module or require.main.filename).toLowerCase()
  # TODO: need to confirm if @ refers to module or global context
  @__NAMESPACE = name  if name?
  @__NAMESPACE

# Add a task
task = (name, deps, opts, action) ->
  ns = namespace()
  # help.add ns, name, deps, opts
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
  console.log ">>> #{task_name}"
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
  log: log
  namespace: namespace
  task: task
  sh: sh
  gulp: gulp
  src: gulp.src
  dest: gulp.dest
  watch: gulp.watch
