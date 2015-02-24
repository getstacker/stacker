ArgumentParser = require('argparse').ArgumentParser

# globals
log = require 'stacker/log'

args = null
parser = null

initParser = ->
  pkg = require '../package.json'
  parser = new ArgumentParser
    version: pkg.version
    prog: pkg.name
    addHelp: true
    description: "#{pkg.description} v#{pkg.version}."
    epilog: 'For additional information, see https://github.com/getstacker/stacker'
    # conflictHandler: [function to resolve option conflicts]

  parser.addArgument ['-c', '--config'],
    help: 'JSON or YAML stacker config file.'
    metavar: 'CONFIG'
    dest: 'stackerfile'

  subparsers = parser.addSubparsers
    title: 'Commands'
    dest: 'command'

  sub_config = subparsers.addParser 'config', addHelp: true, help: 'config stuff'
  # sub_config.addArgument ['-f', '--foo'],
  #   action: 'store',
  #   help: 'foo3 bar3'

  # sub_config2 = subparsers.addParser 'config:show', addHelp: true, help: 'show config stuff'
  # sub_config2.addArgument ['-f', '--foo'],
  #   action: 'store',
  #   help: 'foo3 bar3'

parse = ->
  args = parser.parseArgs()


initParser()
module.exports =
  parse: parse
  printHelp: parser.printHelp
  get: (opt) ->
    if opt then args[opt] else args
