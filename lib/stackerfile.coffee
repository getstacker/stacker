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
load = (stackerfiles) ->
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
    ext = filename.split('.').pop()
    switch ext
      when 'yaml', 'yml'
        stacker = yaml.safeLoad contents
      when 'json'
        stacker = JSON.parse contents
      else
        throw "Unsupported stacker config file type: #{ext}"
    stacker

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
  load: load
