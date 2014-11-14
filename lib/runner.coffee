gulp = require 'gulp'
path = require 'path'
Promise = require 'bluebird'
readFile = Promise.promisify require('fs').readFile

# Make files in global dir available to all plugins via `require('module')`
process.env.NODE_PATH = path.resolve(__dirname, './global') + path.delimiter + process.env.NODE_PATH
require('module').Module._initPaths()  # Hack

dsl = require './dsl'
tasks = require './tasks'

# global
log = require 'log'
help = require 'help'
config = require 'config'


run = ->
  loadStack 'stack.json'
  # loadConfig
  .then tasks.load
  .then ->
    args = process.argv.slice 2
    throw 'NOARGS'  unless args[0]
    gulp.start args[0]
  .catch (err) ->
    log.error err.message or err  unless err == 'NOARGS'
    dsl.dsl.printHelp()


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


module.exports =
  run: run
