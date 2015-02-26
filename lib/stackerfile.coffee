# Load stackerfile
#
# Stackerfile is the stacker.[json|yaml] config file.


path = require 'path'
yaml = require 'js-yaml'

# global
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

readFile = Promise.promisify require('fs').readFile

STACKERFILES = [ 'stacker.json', 'stacker.yaml', 'stacker.yml' ]


# Load the first matching file in stackerfiles.
# Order is not guaranteed. The first file to load wins.
load = (stackerfiles, opts = {}) ->
  _.defaults opts,
    warnings: true

  # Use the first stacker.* file found
  stackerfiles ?= STACKERFILES
  stackerfiles = [ stackerfiles ]  unless _.isArray stackerfiles

  promises = for filename in stackerfiles
    do (filename) ->
      readFile path.normalize(filename), 'utf8'
      .then (contents) ->
        [ filename, contents ]

  Promise.any promises
  .spread (filename, contents) ->
    parse filename, contents

  # Catch errors where nothing was resolved by Promise.any
  .catch Promise.AggregateError, (errors) ->
    paths = for err in errors
      if err.code == 'ENOENT'
        err.path
      else
        log.error err
        process.exit 1
    if opts.warnings
      log.warn 'No stacker config file found: %s', paths.join(', ')
    [ null, {} ]

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


# Parse yaml or json
parse = (filename, contents) ->
  [..., ext] = filename.split '.'
  switch ext
    when 'yaml', 'yml'
      stacker = yaml.safeLoad contents
    when 'json'
      # Strip comments from json
      contents = contents.replace(/\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*\/+/g, '').replace(/\/\/.*/g, '')
      stacker = JSON.parse contents
    else
      throw "Unsupported stacker config file type: #{ext}"
  [ path.resolve(filename), stacker ]


module.exports =
  load: load
