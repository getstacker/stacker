path = require 'path'

__help = {}

getHelp = (task_name) ->
  return __help  if task_name == undefined
  __help[task_name]

setHelp = (task_name, deps, opts) ->
  __help[task_name] =
    deps: deps
    opts: opts
    # file: file
#      path.resolve __dirname, require.main.filename

module.exports =
  getHelp: getHelp
  setHelp: setHelp
