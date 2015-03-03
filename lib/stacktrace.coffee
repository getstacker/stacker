chalk = require 'chalk'
util = require 'util'
path = require 'path'

# globals
_ = require 'stacker/_'
log = require 'stacker/log'
config = require 'stacker/config'
{escapeRegExp} = require('stacker/utils').string


# Print nice error message
# opts: filename, source, sourceMap, context
prettyPrintStackTrace = (err, opts = {}) ->
  _.defaults opts,
    context: 3
    clearStack: not (config.stacker.debug or log.willOutput 'debug')

  {filename, source, sourceMap} = opts
  return err  unless filename and source and err.stack?

  stk = err.stack.toString()
  matches = stk.match ///(^(.*\n)*?).*#{escapeRegExp filename}:(\d+):(\d+)///
  return err  unless matches

  isTopStack = matches[1].trim().split('\n').length is 1
  errline = parseInt matches[3]
  errcol = parseInt matches[4]
  return err  unless errline

  # Lookup in sourceMap
  # This is not currently needed since error stack should already be correct
  if sourceMap
    [errline, errcol] = sourceMap.sourceLocation [errline - 1, errcol - 1]
    errline += 1
    errcol += 1

  start = Math.max errline - 1 - opts.context, 0
  linepos = errline - 1
  colpos = errcol - 1
  out = for line,i in source.split('\n')[start .. linepos + opts.context]
    num = i + start + 1
    len = Math.abs 4 - Math.floor(Math.log10 num or 1)
    padding = new Array(len or 0).join ' '

    if num is errline
      wordlen = line.slice(colpos).search /[\(\)\s\.:]/
      word = line.substr colpos, wordlen
      first = line.slice 0, colpos
      last = line.substr colpos + wordlen
      line = "#{first}#{chalk.red word}#{last}"
    "#{chalk.white num}:#{padding}#{line}"

  stack = util.format 'Error in task file: %s line %d column %d\n\nFile: %s\n>>>>  %s\n\n%s\n',
    filename,
    errline, errcol,
    chalk.cyan(path.relative process.cwd(), filename),
    chalk.red(err.message),
    out.join "\n"

  stack += "\n" + err.stack  unless opts.clearStack and isTopStack

  err.stack = stack
  err


module.exports =
  prettyPrintStackTrace: prettyPrintStackTrace
