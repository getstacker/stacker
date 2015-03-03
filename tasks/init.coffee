require 'shelljs/global'
# path = require 'path'
# for cmd,func of shell
#   global[cmd] = func  unless __dsl[cmd]

test = require '../tasks/dev/testtest'

# testtest()


# String::to = () ->
#   console.log '!!!! to'

# console.log '???????'
# log.debug 'String: ', String.prototype

packageJSON = ->
  pkg =
    dependencies: config.stacker.dependencies
  JSON.stringify pkg, null, '  '


task 'init', help: 'Install plugins and dependencies', ->
  # TODO run `npm install --prefix=.stacker` in stacker dir

  log.debug 'yo', config
  test()
  testtest()
  return
  assert config?.stacker?.dir, "dir must be set in stacker config: #{config.stackerfile}"

  mkdir '-p', config.stacker.dir
  console.log path.resolve(config.stacker.dir, 'package.json')
  console.log packageJSON()
  packageJSON().to path.resolve(config.stacker.dir, 'package.json')
  #yo()
  #test()
  #sh()


  # assert false, new Error('yo yo')

  # mkdirp config.sta




#asdfasdf()
