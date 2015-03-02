chalk = require 'chalk'
util = require 'util'
path = require 'path'

# globals
_ = require 'stacker/_'
log = require 'stacker/log'
{escapeRegExp} = require('stacker/utils').string


# Print nice error message
# opts: filename, source, sourceMap, context
prettyPrintStackTrace = (err, opts = {}) ->
  _.defaults opts,
    context: 3
    clearStack: true
  {filename, source, sourceMap} = opts

  return err  unless filename and source and err.stack?

  stk = err.stack.toString()
  matches = stk.match ///#{escapeRegExp filename}:(\d+):(\d+)///
  return err  unless matches

  # TODO: make isSource detection more robust by looking up the filename in
  #   list of tasks to ensure filename is actually a task

  # Assume errline refers to original source if filename is not the last file in the stack
  isSource = not stk.match(///^.*\n[^\n]+#{escapeRegExp filename}///)?

  errline = parseInt matches[1]
  errcol = parseInt matches[2]

  # Only do a sourceMap look up if the error was thrown from a task file.
  # This works because the task files are custom compiled where everything else
  # is compiled by normal CoffeeScript methods and is already correct in the stack.
  if not isSource
    # Error refers to compiled JS code; get cooresponding source
    if sourceMap?
      [errline, errcol] = sourceMap.sourceLocation [errline - 1, errcol - 1]
  else
    # Error refers to source; adjust line & col so proceeding math works
    errline -= 1
    errcol -= 1
  return err  unless errline

  start = Math.max errline - opts.context, 0
  out = for line,i in source.split('\n')[start..errline+opts.context]
    num = i + start
    len = Math.abs 4 - Math.floor(Math.log10 num or 1)
    padding = new Array(len or 0).join ' '

    if num is errline
      wordlen = line.slice(errcol).search /[\(\)\s\.:]/
      word = line.substr errcol, wordlen
      first = line.slice 0, errcol
      last = line.substr errcol + wordlen
      line = "#{first}#{chalk.red word}#{last}"
    "#{chalk.white num+1}:#{padding}#{line}"

  err.message = util.format 'Error in task file: %s line %d column %d\n\nFile: %s\n>>>>  %s\n\n%s\n',
    filename,
    errline+1, errcol+1,
    chalk.cyan(path.relative process.cwd(), filename),
    chalk.red(err.message),
    out.join "\n"

  # Clear stack trace since the line numbers are incorrect
  err.stack = undefined  if opts.clearStack

  err


module.exports =
  prettyPrintStackTrace: prettyPrintStackTrace
