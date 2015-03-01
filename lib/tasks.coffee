vm = require 'vm'
path = require 'path'
util = require 'util'
chalk = require 'chalk'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
dsl = require './dsl'


# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'
{escapeRegExp} = require('stacker/utils').string

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
  #contents = dsl.inject contents.toString()
  code = CoffeeScript.compile contents,
    filename: filename
    sourceMap: true
  taskSandbox =
    Buffer: Buffer
    Error: Error
    console: console
    require: require
    process: process
    setImmediate: setImmediate
    clearImmediate: clearImmediate

  try
    vm.runInNewContext code.js, taskSandbox,
      filename: filename
      displayErrors: false
  catch err
    throw prettyPrintStackTrace err, filename, contents, code.sourceMap


prettyPrintStackTrace = (err, filename, source, sourceMap) ->
  stk = err.stack.toString()
  matches = stk.match ///#{escapeRegExp filename}:(\d+):(\d+)///
  return err  unless matches
  errline = parseInt matches[1]
  errcol = parseInt matches[2]
  [errline, errcol] = sourceMap.sourceLocation [errline - 1, errcol - 1]

  return err  unless errline

  start = Math.max errline - 3, 0
  out = for line,i in source.split('\n')[start..start+6]
    num = i + start
    len = Math.abs 4 - Math.floor(Math.log10 num or 1)
    padding = new Array(len or 0).join ' '
    if num is errline
      wordlen = line.slice(errcol).search /[\(\s\.]/
      word = line.substr errcol, wordlen
      first = line.slice 0, errcol
      last = line.substr errcol + wordlen
      line = "#{first}#{chalk.red word}#{last}"
    "#{chalk.white num+1}:#{padding}#{line}"
  relpath = path.relative process.cwd(), filename
  err.message = util.format 'Error in task file: %s line %d column %d\n\nFile: %s\n>>>>  %s\n\n%s\n',
    relpath,
    errline+1, errcol+1,
    chalk.cyan(relpath),
    chalk.red(err.message),
    out.join "\n"
  err.code = 'TASKERROR'
  # Clear stack trace since the line numbers are incorrect
  err.stack = undefined
  err



module.exports =
  load: load
  parse: parse
