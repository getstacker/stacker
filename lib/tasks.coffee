path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'

# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

glob = Promise.promisify require 'glob'
readFile = Promise.promisify require('fs').readFile


# Load tasks files that match the src glob
load = (src) ->
  glob src,
    cwd: __dirname
    sync: false
  .then readTaskFiles
  .all()


readTaskFiles = (files) ->
  for file in files
    do (file) ->
      file = path.resolve __dirname, file
      readFile file, 'utf8'
      .then (contents) ->
        # Inject dsl into file
        contents = dsl.inject contents.toString()
        # log.debug contents
        CoffeeScript.run contents,
          filename: file
      .catch (err) ->
        log.error "Invalid task file: #{path.relative process.cwd(), file}"
        log.error "-->  #{err.message}"
        log.error err.stack


module.exports =
  load: load
