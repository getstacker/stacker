gulp = require 'gulp'
path = require 'path'
yaml = require 'js-yaml'

dsl = require('./dsl').dsl
tasks = require './tasks'
args = require './args'

# global
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'
config = require 'stacker/config'

readFile = Promise.promisify require('fs').readFile


run = ->
  args.parse()
  loadConfig args.get 'stackerfile'
  .then tasks.load
  .then ->
    cmd = args.get 'command'
    throw 'NOARGS'  unless cmd
    gulp.start cmd
  .catch (err) ->
    log.error(err.message or err)  unless err == 'NOARGS'
    dsl.printHelp()


loadConfig = (stackerfile) ->
  # Use the first stacker.* file found
  files = stackerfile and [stackerfile] or ['stacker.json', 'stacker.yaml', 'stacker.yml']
  files = [args.config]  if args.config
  promises = for filename in files
    do (filename) ->
      readFile path.normalize(filename), 'utf8'
      .then (contents) ->
        [ filename, contents ]
  Promise.any promises
  .spread (filename, contents) ->
    ext = filename.split('.').pop()
    switch ext
      when 'yaml', 'yml'
        config.stacker = yaml.safeLoad contents
      when 'json'
        config.stacker = JSON.parse contents
      else
        throw "Unsupported stacker config file type: #{ext}"
    # log.debug config
    # args.applyToConfig config

  # Catch errors where nothing was resolved by Promise.any
  .catch Promise.AggregateError, (errors) ->
    paths = for err in errors
      if err.code == 'ENOENT'
        err.path
      else
        log.error err
        process.exit 1
    log.warn 'No stacker config file found: %s', paths.join(', ')

  # Catch file processing errors
  .catch (err) ->
    if err instanceof SyntaxError
      log.error 'Invalid JSON syntax in %s:', filename, err.message
      log.error err
    else if err instanceof yaml.YAMLException
      log.error 'Invalid YAML in %s:', filename, err.message
    else
      log.error err
    log.error err.stack  if err.stack
    process.exit 1

module.exports =
  run: run
