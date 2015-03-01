vm = require 'vm'
path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'
{prettyPrintStackTrace} = require './stacktrace'

# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

glob = Promise.promisify require 'glob'
readFile = Promise.promisify require('fs').readFile

# Cache of loaded task file contents
taskFiles = []

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
  code = CoffeeScript.compile source,
    filename: filename
    sourceMap: true
    bare: false # Source maps don't work unless bare is false for some reason

  sandbox =
    Buffer: Buffer
    Error: Error
    console: console
    require: require
    process: process
    setImmediate: setImmediate
    clearImmediate: clearImmediate
    __filename: filename
    __dirname: path.dirname filename
    __source: source
    __sourceMap: code.sourceMap
    __dsl: dsl.dsl

  sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox

  for k,v of dsl.dsl
    sandbox[k] = if typeof v is 'function'
      v.bind sandbox
    else
      v

  try
    vm.runInNewContext code.js, sandbox,
      filename: filename
      displayErrors: false
  catch err
    err.code = 'TASKERROR'
    throw prettyPrintStackTrace err,
      filename: filename
      source: source
      sourceMap: code.sourceMap
      clearStack: false # TODO: set clearStack based on log level debug



module.exports =
  load: load
  parse: parse
