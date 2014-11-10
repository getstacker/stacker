
path = require 'path'
gulp = require 'gulp'
fs = require 'fs'
glob = require 'glob'
CoffeeScript = require 'coffee-script/lib/coffee-script/coffee-script'
Promise = require 'bluebird'
readFile = Promise.promisify fs.readFile
_ = require 'lodash'


# Make files in global dir available to all plugins via `require('module')`
process.env.NODE_PATH = path.resolve(__dirname, './global') + path.delimiter + process.env.NODE_PATH
require('module').Module._initPaths()  # Hack

log = require 'log'  # global/log
dsl = require './dsl'


run = ->
  # Make DSL available to command files processed by CoffeeScript
  _.extend global, dsl
  args = process.argv.slice 2
  opts =
    cwd: __dirname
    sync: true
  glob '../**/**/commands/*', opts, (err, files) ->
    files = for file in files
      file = path.resolve __dirname, file
      readFile file, 'utf8'
      .then (contents) ->
        contents = parse contents.toString()
        CoffeeScript.run contents,
          filename: file
      .catch (err) ->
        log.error "Invalid task file: #{path.relative process.cwd(), file}"
        log.error "-->  #{err.message}"
    Promise.all files
    .then ->
      gulp.start args[0]  if args[0]


parse = (contents) ->
  # Add `yield` in front of sh calls nested in a task
  contents = contents.replace /^(\s{2,})(sh\s)/mg, '$1yield $2'
  contents

module.exports =
  run: run
