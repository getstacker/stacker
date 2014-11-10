
gulp = require 'gulp'
fs = require 'fs'
path = require 'path'
glob = require 'glob'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
Promise = require 'bluebird'
co = require 'co'
stream = require 'stream'
_ = require 'lodash'


# Make files in global dir available to all plugins via `require('module')`
process.env.NODE_PATH = path.resolve(__dirname, './global') + path.delimiter + process.env.NODE_PATH
require('module').Module._initPaths()  # Hack

#
# Stacker DSL
#
_.extend global,
  # Set the namespace for proceeding tasks
  namespace: (name) ->
    # plugin = path.basename(opts.module or require.main.filename).toLowerCase()
    # TODO: need to confirm if @ refers to module or global context
    @__NAMESPACE = name  if name?
    @__NAMESPACE

  # Add a task
  task: (name, deps, opts, action) ->
    ns = namespace()
    # help.add ns, name, deps, opts
    args = Array.prototype.slice.call arguments, 0
    deps = findParam args, 'Array'
    opts = findParam args, 'Object'
    action = findParam args, 'Function'
    ns = if ns then "#{ns}:" else ''
    console.log ">>> #{ns}#{name}"
    gulp.task "#{ns}#{name}", deps, (cb) ->
      new Promise (resolve, reject) ->
        co( ->
          try
            ret = yield action cb
            resolve ret
          catch err
            reject err
        )()
      .catch (err) ->
        log.error err

  # Run a shell command
  sh: (cmd, opts) ->
    ps.spawn 'sh', ['-c', cmd], opts


findParam = (params, type) ->
  for p, i in params
    return p  if _["is#{type}"] p
  new global[type]


run = ->
  args = process.argv.slice 2
  opts =
    cwd: __dirname
    sync: true
  glob '../**/**/commands/*', opts, (err, files) ->
    for file in files
      file = path.resolve __dirname, file
      try
        contents = fs.readFileSync file
        contents = parse contents.toString()
        CoffeeScript.run contents,
          filename: file
      catch err
        log.error "Invalid task file: #{path.relative process.cwd(), file}"
        log.error "-->  #{err.message}"
  gulp.start args[0]  if args[0]


parse = (contents) ->
  # Add `yield` in front of sh calls nested in a task
  contents = contents.replace /^(\s{2,})(sh\s)/mg, '$1yield $2'
  contents

module.exports =
  run: run
