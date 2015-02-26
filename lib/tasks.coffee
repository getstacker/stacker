path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'

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
  # Inject dsl into file
  contents = dsl.inject contents.toString()
  # log.debug contents
  CoffeeScript.run contents,
    filename: filename



module.exports =
  load: load
  parse: parse
