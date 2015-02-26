util = require 'util'


task 'debug', ['debug:config', 'debug:dsl'], help: 'Show config and DSL', ->


task 'debug:config', help: 'Show looaded stacker config', ->
  console.log "\n==== STACKERFILE CONFIG ====\n"
  console.log util.inspect config, depth: null, colors: true
  console.log "\n\n"

task 'debug:dsl', help: 'Show DSL', ->
  console.log ""
  keys = Object.keys(__stacker__.dsl).sort()
  for k in keys
    v = __stacker__.dsl[k]
    n = if typeof v == 'object' then "\n" else ''
    console.log "#{k}: #{n}#{util.inspect v, depth: 0, colors: true}\n"

