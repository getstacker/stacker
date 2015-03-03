path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'
{prettyPrintStackTrace} = require './stacktrace'
Sandbox = require './Sandbox'

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
    # Source maps are wrong unless bare is false for some reason
    bare: false
  try
    vm = new Sandbox
      filename: filename
      code: code.js
      source: source
      sourceMap: code.sourceMap
      dsl: dsl.dsl
    vm.run()
  catch err
    err.code = 'TASKERROR'
    # Errors occur here when task files fail to initialize properly.
    # This typically happens when a DSL methods are missing.
    # See dsl.task for catching task runtime errors.
    throw prettyPrintStackTrace err,
      filename: filename
      source: source
      # Use sourceMap since errors occur before prepareStackTrace is available
      sourceMap: code.sourceMap


module.exports =
  load: load
  parse: parse
