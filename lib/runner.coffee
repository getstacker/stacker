
path = require 'path'
gulp = require 'gulp'
fs = require 'fs'
glob = require 'glob'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
Promise = require 'bluebird'
readFile = Promise.promisify fs.readFile
_ = require 'lodash'
Table = require 'cli-table'

# Make files in global dir available to all plugins via `require('module')`
process.env.NODE_PATH = path.resolve(__dirname, './global') + path.delimiter + process.env.NODE_PATH
require('module').Module._initPaths()  # Hack

log = require 'log'    # global/log
help = require 'help'  # global/help
dsl = require './dsl'



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
    "#{k} = __stacker__.#{k}"
  [
    "__stacker__ = require('#{path.resolve __dirname, './dsl'}').dsl"
    vars.join "\n"
    '__namespace__ = ""'
    'task = -> args = Array.prototype.slice.call(arguments); args.unshift(__namespace__); __stacker__.task.apply null, args'
    "\n"
    contents
  ]
  .join "\n"


run = ->
  args = process.argv.slice 2
  opts =
    cwd: __dirname
    sync: true
  glob '../**/**/commands/*', opts, (err, files) ->
    files = for file in files
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
    Promise.all files
    .then ->
      throw 'NOARGS'  unless args[0]
      gulp.start args[0]
    .catch (err) ->
      log.error err.message or err  unless err == 'NOARGS'
      printHelp()


printHelp = ->
  table = new Table
    head: ['Command', 'Description']
    style:
      compact: true
  for name, h of help.getHelp()
    table.push [name, h.opts.desc or '']
  console.log table.toString()


module.exports =
  run: run
