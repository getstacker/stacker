argparse = require 'stacker-args'

# globals
_ = require 'stacker/_'
log = require 'stacker/log'

args = null
parser = null
subparsers = null
commands = {}


pkg = require '../package.json'

createParser = (opts = {}) ->
  _.defaults opts,
    addHelp: true
    subcommands: true

  newParser = new argparse.ArgumentParser
    version: pkg.version
    prog: pkg.name
    addHelp: opts.addHelp
    description: "#{pkg.description} v#{pkg.version}."
    epilog: 'For additional information, see https://github.com/getstacker/stacker'
    formatterClass: argparse.ArgumentDefaultsHelpFormatter
    conflictHandler: 'resolve'

  newParser.addArgument ['--config'],
    help: 'JSON or YAML stacker config file.'
    metavar: 'CONFIG'
    dest: 'config'
    defaultValue: null

  newParser.addArgument ['--env'],
    help: 'Set environment ENV var'
    metavar: 'ENV'
    dest: 'environment'
    defaultValue: 'development'

  newParser.addArgument ['--dir'],
    help: 'Location of stacker dir'
    metavar: 'DIR'
    dest: 'dir'
    defaultValue: '.stacker'

  if opts.subcommands
    subparsers = newParser.addSubparsers
      title: 'Task commands'
      dest: 'task'
      description: 'Commands are defined in task files. Task specific help: stacker COMMAND -h'
      metavar: 'COMMAND'
      help: ''

  newParser


# Manage subparsers
command = (cmd, opts = {}) ->
  return commands[cmd]  if commands[cmd]?
  opts.addHelp = opts.help?
  commands[cmd] = opts


# Return subset of known args if present
parseKnown = ->
  tmpparser = createParser addHelp: false, subcommands: false
  args = tmpparser.parseKnownArgs()[0]


setConfig = (conf) ->
  conf.environment = args['environment']
  conf.dir = args['dir']
  # Do not set args['config']; it is set in runner
  conf


# Sort commands before adding parsers
# HACK: sorting should be handled in the args help formatter
sortCommands = ->
  cmdarr = for k,v of commands
    [k, v]
  cmdarr.sort (a, b) ->
    if a[0] < b[0] then -1
    else if a[0] > b[0] then 1
    else 0


parse = ->
  for arr in sortCommands()
    subparsers.addParser.apply subparsers, arr
  commands = []
  args = parser.parseArgs()


parser = createParser()

module.exports =
  parseKnown: parseKnown
  parse: parse
  printHelp: parser.printHelp.bind(parser)
  formatHelp: parser.formatHelp.bind(parser)
  command: command
  addArgument: parser.addArgument.bind(parser)
  setConfig: setConfig
  get: (opt) ->
    if opt then args[opt] else args
