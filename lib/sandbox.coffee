# Sandbox class

path = require 'path'
vm = require 'vm'
Module = require 'module'
SandboxModule = require './sandbox-module'

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

    @setSandboxModule sandbox
    #@setModule sandbox
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


  ###
  setModule is a hack.
  Modules loaded in the VM that modify global or built-in objects will
  pollute this context. TODO: get SandboxModule working.
  ###
  # setModule: (sandbox) ->
  #   # Set modules loading paths
  #   # https://github.com/jashkenas/coffeescript/blob/533ad8/src/coffee-script.coffee#L154-L161
  #   sandbox.module  = _module  = new Module @opts.modulename
  #   sandbox.require = _require = (path) ->  Module._load path, _module, true
  #   _module.filename = sandbox.__filename
  #   skip = ['paths', 'callee', 'caller', 'arguments']
  #   _require[r] = require[r] for r in Object.getOwnPropertyNames require when not _.contains(skip, r)
  #   # use the same hack node currently uses for their own REPL
  #   _require.paths = _module.paths = @modulePaths()
  #   _require.resolve = (request) -> Module._resolveFilename request, _module
  #   sandbox


  ###
  SandboxModule is experimental.
  The goal with SandboxModule is to share global scope so loaded modules
  can modify built-in objects (like String) or add to the globals.
  ###
  setSandboxModule: (sandbox) ->
    # TODO: create helper method on SandboxModule
    #   This code is duplicated in SandboxModule

    sandbox.module  = _module  = new SandboxModule @opts.modulename
    _module.filename = sandbox.__filename

    sandbox.require = _require = (path) ->
      log.debug 'sandbox.require: ', path
      SandboxModule._load path, _module, true, sandbox
    _require.resolve = (request) ->
      SandboxModule._resolveFilename request, _module
    _require.main = process.mainModule
    _require.extensions = SandboxModule._extensions
    _require.cache = SandboxModule._cache

    # use the same hack node currently uses for their own REPL
    _require.paths = _module.paths = @modulePaths()
    log.warn '_require.paths', _require.paths

    sandbox


  modulePaths: ->
    # Module._nodeModulePaths process.cwd()
    _.compact [
      # Stacker install dir; built-in modules
      path.resolve __dirname, '../node_modules'
      # Project .stacker dir
      path.resolve config.stacker.dir, 'node_modules'
    ]


module.exports = Sandbox
