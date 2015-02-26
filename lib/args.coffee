argparse = require 'stacker-args'

# globals
log = require 'stacker/log'

args = null
parser = null
subparsers = null
commands = {}

CONFIG_ARGS = ['--config']


pkg = require '../package.json'
parser = new argparse.ArgumentParser
  version: pkg.version
  prog: pkg.name
  addHelp: true
  description: "#{pkg.description} v#{pkg.version}."
  epilog: 'For additional information, see https://github.com/getstacker/stacker'
  formatterClass: argparse.ArgumentDefaultsHelpFormatter
  conflictHandler: 'resolve'

parser.addArgument CONFIG_ARGS,
  help: 'JSON or YAML stacker config file.'
  metavar: 'CONFIG'
  dest: 'config'
  defaultValue: ''

parser.addArgument ['--env'],
  help: 'Set environment ENV var'
  metavar: 'ENV'
  dest: 'env'
  defaultValue: 'development'

subparsers = parser.addSubparsers
  title: 'Task commands'
  dest: 'task'
  description: 'Commands are defined in task files. Task specific help: stacker COMMAND -h'
  metavar: 'COMMAND'
  help: ''



# Manage subparsers
command = (cmd, opts = {}) ->
  return commands[cmd]  if commands[cmd]?
  opts.addHelp = opts.help?
  commands[cmd] = subparsers.addParser cmd, opts


# Return --config arg if present
getConfig = ->
  configparser = new argparse.ArgumentParser
    addHelp: false
  configparser.addArgument CONFIG_ARGS,
    dest: 'config'
  configparser.parseKnownArgs()[0]['config']


parse = ->
  args = parser.parseArgs()


module.exports =
  parse: parse
  getConfig: getConfig
  printHelp: parser.printHelp.bind(parser)
  formatHelp: parser.formatHelp.bind(parser)
  command: command
  addArgument: parser.addArgument.bind(parser)
  get: (opt) ->
    if opt then args[opt] else args
