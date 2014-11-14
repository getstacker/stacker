
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
gulp = require 'gulp'
path = require 'path'
Promise = require 'bluebird'
glob = Promise.promisify require 'glob'
readFile = Promise.promisify require('fs').readFile
_ = require 'lodash'

# Make files in global dir available to all plugins via `require('module')`
process.env.NODE_PATH = path.resolve(__dirname, './global') + path.delimiter + process.env.NODE_PATH
require('module').Module._initPaths()  # Hack

dsl = require './dsl'

# global
log = require 'log'
help = require 'help'
config = require 'config'

COMMANDS_SRC = '../**/**/commands/*'


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


run = ->
  loadStack 'stack.json'
  .then loadTasks


loadStack = (filename, encoding = 'utf8') ->
  readFile path.normalize(filename), encoding
  .then (contents) ->
    config.stack = JSON.parse contents
  .catch (err) ->
    if err.cause and err.cause.code == 'ENOENT'
      return log.debug 'No stack file:', filename
    if err instanceof SyntaxError
      log.error "Invalid JSON syntax in #{filename}:", err.message
      process.exit 1
    log.error err.stack


loadTasks = ->
  args = process.argv.slice 2
  opts =
    cwd: __dirname
    sync: true
  glob COMMANDS_SRC, opts
  .then (files) ->
    readTaskFiles files
  .all()
  .then ->
    throw 'NOARGS'  unless args[0]
    gulp.start args[0]
  .catch (err) ->
    log.error err.message or err  unless err == 'NOARGS'
    dsl.dsl.printHelp()


readTaskFiles = (files) ->
  for file in files
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



module.exports =
  run: run
