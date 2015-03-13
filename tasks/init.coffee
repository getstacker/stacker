require 'stacker-shelljs/global'
path = require 'path'

packageJSON = ->
  pkg =
    dependencies: config.stacker.dependencies
  JSON.stringify pkg, null, '  '

task 'init', help: 'Install plugins and dependencies', ->
  # TODO run `npm install --prefix=.stacker` in stacker dir
  assert config?.stacker?.dir, "dir must be set in stacker config: #{config.stackerfile}"
  mkdir '-p', config.stacker.dir
  packageJSON().to path.resolve(config.stacker.dir, 'package.json')
