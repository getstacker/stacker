# Sandbox class

path = require 'path'
vm = require 'vm'
Module = require 'module'

# globals
_ = require 'stacker/_'
log = require 'stacker/log'
config = require 'stacker/config'


class Sandbox
  # JavaScript to tack on to the end of all code before running in VM.
  # Code is appended rather than prepended so that source maps are stil accurate.
  codeAddons: """
  ; Error.prepareStackTrace = __prepareStackTrace;
  """

  constructor: (opts = {}) ->
    {@filename, @code, @source, @sourceMap, @sandbox, @dsl} = opts
    @opts = opts
    _.defaults @opts,
      modulename: 'eval'
    @init()


  init: ->
    sandbox = @sandbox or @newSandbox()

    sandbox.__filename = @filename
    sandbox.__dirname = path.dirname @filename
    sandbox.__source = @source
    sandbox.__sourceMap = @sourceMap

    @setModule sandbox
    @sandbox = sandbox


  run: (opts = {}) ->
    _.defaults opts,
      filename: @filename
      displayErrors: false
    vm.runInNewContext @code + @codeAddons, @sandbox, opts


  newSandbox: (filename, source, sourceMap) ->
    sandbox =
      Buffer: Buffer
      console: console
      process: process
      setImmediate: setImmediate
      clearImmediate: clearImmediate
      assert: require 'assert'
      __dsl: @dsl
      __prepareStackTrace: Error.prepareStackTrace

    sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox

    for k,v of @dsl
      sandbox[k] = if _.isFunction(v) then v.bind(sandbox) else v

    sandbox


  setModule: (sandbox) ->
    # Set modules loading paths
    # https://github.com/jashkenas/coffeescript/blob/533ad8/src/coffee-script.coffee#L154-L161
    sandbox.module  = _module  = new Module @opts.modulename
    sandbox.require = _require = (path) ->  Module._load path, _module, true
    _module.filename = sandbox.__filename
    skip = ['paths', 'callee', 'caller', 'arguments']
    _require[r] = require[r] for r in Object.getOwnPropertyNames require when not _.contains(skip, r)
    # use the same hack node currently uses for their own REPL
    _require.paths = _module.paths = @modulePaths()
    _require.resolve = (request) -> Module._resolveFilename request, _module
    sandbox


  modulePaths: ->
    _.compact [
      # Stacker install dir; built-in modules
      path.resolve __dirname, '../node_modules'
      # Project .stacker dir
      path.resolve config.stacker.dir, 'node_modules'
    ]


module.exports = Sandbox
