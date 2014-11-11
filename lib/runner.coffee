
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
        CoffeeScript.run parse contents,
          filename: file
      .catch (err) ->
        log.error "Invalid task file: #{path.relative process.cwd(), file}"
        log.error "-->  #{err.message}"
        log.error err.stack
    # TODO: confirm that async is not going to screw up namespacing in DSL
    #   Probably need to grep for namespace and inject it into tasks
    Promise.all files
    .then ->
      throw 'NOARGS'  unless args[0]
      gulp.start args[0]
    .catch (err) ->
      log.error err.message or err  unless err == 'NOARGS'
      printHelp()


parse = (contents) ->
  contents = contents.toString()
  # Add `yield` in front of sh calls nested in a task
  contents = contents.replace /^(\s{2,})(sh\s)/mg, '$1yield $2'
  injectDSL contents


injectDSL = (contents) ->
  vars = for k,v of dsl
    "#{k} = __dsl__.#{k}"
  dsl_path = path.resolve __dirname, 'dsl'
  """
    __dsl__ = require '#{dsl_path}'
    #{vars.join "\n"}

    #{contents}
  """


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
