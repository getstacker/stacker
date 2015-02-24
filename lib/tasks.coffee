path = require 'path'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'

# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

glob = Promise.promisify require 'glob'
readFile = Promise.promisify require('fs').readFile



load = (src) ->
  opts =
    cwd: __dirname
    sync: false
  glob src, opts
  .then (files) ->
    readTaskFiles files
  .all()


readTaskFiles = (files) ->
  for file in files
    do (file) ->
      file = path.resolve __dirname, file
      readFile file, 'utf8'
      .then (contents) ->
        contents = parse contents
        # log.debug contents
        CoffeeScript.run contents,
          filename: file
      .catch (err) ->
        log.error "Invalid task file: #{path.relative process.cwd(), file}"
        log.error "-->  #{err.message}"
        log.error err.stack


parse = (contents) ->
  contents = contents.toString()
  # Add `yield` in front of async dsl methods
  yieldfor = dsl.yieldfor.join '|'
  re = new RegExp "^([^#]*?\\s+)(#{yieldfor})\\s(.+?)$", 'mg'
  contents = contents.replace re, '$1yield $2 $3'
  # Convert namespace into local variable
  contents = contents.replace /(\s*)namespace\s+(['"].*)/g, '$1__namespace__ = $2'
  inject contents


inject = (contents) ->
  vars = for k,v of dsl.dsl
    "#{k} = __stacker__.dsl.#{k}"
  [
    "__stacker__ = {dsl: require('#{path.resolve __dirname, './dsl'}').dsl}"
    vars.join "\n"
    '__namespace__ = ""'
    'task = -> args = Array.prototype.slice.call(arguments); args.unshift(__namespace__); __stacker__.dsl.task.apply null, args'
    "\n"
    contents
  ]
  .join "\n"


module.exports =
  load: load

