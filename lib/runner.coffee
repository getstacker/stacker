gulp = require 'gulp'
path = require 'path'

dsl = require('./dsl').dsl
tasks = require './tasks'

# global
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'
config = require 'stacker/config'

readFile = Promise.promisify require('fs').readFile


run = ->
  loadConfig 'stack.json'
  .then tasks.load
  .then ->
    args = process.argv.slice 2
    throw 'NOARGS'  unless args[0]
    gulp.start args[0]
  .catch (err) ->
    log.error(err.message || err)  unless err == 'NOARGS'
    dsl.printHelp()


loadConfig = (filename, encoding = 'utf8') ->
  readFile path.normalize(filename), encoding
  .then (contents) ->
    config.stack = JSON.parse contents
  .catch (err) ->
    if err.cause and err.cause.code == 'ENOENT'
      return log.warn 'No stack file:', filename
    if err instanceof SyntaxError
      log.error "Invalid JSON syntax in #{filename}:", err.message
      process.exit 1
    log.error err.stack


module.exports =
  run: run
