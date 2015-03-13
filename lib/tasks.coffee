path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'
{prettyPrintStackTrace} = require './stacktrace'
SandboxedModule = require 'stacker-sandboxed'
stackTrace = require 'stack-trace'

# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

glob = Promise.promisify require 'glob'
readFile = Promise.promisify require('fs').readFile

# Cache of loaded task file contents
taskFiles = []

# Override coffeescrpt source transformer to include sourceMaps
SandboxedModule.configure sourceTransformers:
  coffee: (source) ->
    if @filename.search('.coffee$') isnt -1
      compiled = CoffeeScript.compile source,
        filename: @filename
        sourceMap: true
      @sourceMap = compiled.sourceMap
      @_options.globals.__sourceMap = compiled.sourceMap
      compiled.js
    else
      source

# Load tasks files that match the src glob
# Returns array of promises
load = (src) ->
  glob src,
    cwd: process.cwd()
    sync: false
    nodir: true
  .then readFiles
  .all()


readFiles = (files) ->
  for filename in files
    do (filename) ->
      filename = path.resolve __dirname, filename
      readFile filename, 'utf8'
      .then (contents) ->
        taskFiles.push [filename, contents]
      .catch (err) ->
        log.error "Invalid task file: #{path.relative process.cwd(), filename}"
        log.error "-->  #{err.message}"
        log.error err.stack


parse = ->
  for params in taskFiles
    parseTask.apply null, params
  taskFiles = null


parseTask = (filename, contents) ->
  source = dsl.inject contents

  globals = {}
  locals = {}
  for k,v of dsl.dsl
    if _.isFunction(v)
      globals[k] = v.bind(globals)
    else
      locals[k] = v
  _.extend globals,
    __filename: filename
    __dirname: path.dirname filename
    __source: source
    __sourceMap: undefined # set by transformer
    __dsl: dsl.dsl

  sandbox = new SandboxedModule
  try
    trace = stackTrace.get parseTask
    sandbox._init filename, trace,
      globals: globals
      locals: locals
    sandbox._compile()
  catch err
    err.code = 'TASKERROR'
    # Errors occur here when task files fail to initialize properly.
    # This typically happens when a DSL methods are missing.
    # See dsl.task for catching task runtime errors.
    throw prettyPrintStackTrace err,
      filename: filename
      source: source
      sourceMap: sandbox.sourceMap


module.exports =
  load: load
  parse: parse
