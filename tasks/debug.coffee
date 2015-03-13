
inspect = (key, val, opts = {}) ->
  opts.depth ?= 0
  opts.colors ?= true
  console.log "#{key}: #{util.inspect val, opts}\n"


task 'debug:config', help: 'Show looaded stacker config', ->
  cli.printHeader cli.color.cyan('STACKERFILE CONFIG')
  inspect 'config', config, depth: 4, colors: true


task 'debug:dsl', help: 'Show DSL functions available in task files', ->
  dslkeys = Object.keys(__dsl).sort()

  cli.printHeader cli.color.cyan('SANDBOX GLOBALS')
  gkeys = Object.keys(global).sort()
  for k in gkeys
    continue  if dslkeys.indexOf(k) > -1 or k.toLowerCase() is 'global' or k is 'root'
    inspect k, global[k], depth: -1

  cli.printHeader cli.color.cyan('STACKER DSL')
  for k in dslkeys
    inspect k, __dsl[k]

