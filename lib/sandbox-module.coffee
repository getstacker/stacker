Module = require 'module'
assert = require 'assert'
path = require 'path'
vm = require 'vm'
fs = require 'fs'

# globals
log = require 'stacker/log'



class SandboxModule extends Module

  @_load = (request, parent, isMain, sandbox) ->
    filename = SandboxModule._resolveFilename request, parent
    # cachedModule = Module._cache[filename]
    # if cachedModule
    #   return cachedModule.exports
    # if NativeModule.exists(filename)
    #   return NativeModule.require(filename)
    module = new SandboxModule(filename, parent)
    module.sandbox = sandbox
    if isMain
      process.mainModule = module
      module.id = '.'
    # Module._cache[filename] = module
    hadException = true
    try
      module.load filename
      hadException = false
    catch err
      log.debug 'SandboxModule load failed for %s', filename, err
      # Fall back to native module loading
      return Module._load request, parent, isMain
    finally
      if hadException
        delete Module._cache[filename]
    module.exports

  # @_resolveFilename = (request, parent) ->
  #   log.debug '>>>> _resolveFilename: %s', request, parent.filename
  #   # if NativeModule.exists(request)
  #   #   return request
  #   [id, paths] = SandboxModule._resolveLookupPaths(request, parent)
  #   # look up the filename first, since that's the cache key.
  #   filename = SandboxModule._findPath(request, paths)
  #   if !filename
  #     # Fall back to resolving file using native Module
  #     return Module._resolveFilename request, parent
  #   filename

  # @_findPath = (request, paths) ->
  #   exts = Object.keys(SandboxModule._extensions)
  #   if request.charAt(0) == '/'
  #     paths = [ '' ]
  #   trailingSlash = request.slice(-1) == '/'
  #   cacheKey = JSON.stringify(
  #     request: request
  #     paths: paths)
  #   if SandboxModule._pathCache[cacheKey]
  #     return SandboxModule._pathCache[cacheKey]
  #   # For each path
  #   i = 0
  #   PL = paths.length
  #   log.debug '>>>>>>> _findPath: %s', request, paths
  #   # return super
  #   while i < PL
  #     basePath = path.resolve(paths[i], request)
  #     log.debug 'basePath: ', basePath
  #     filename = undefined
  #     if !trailingSlash
  #       stats = statPath(basePath)
  #       # try to join the request to the path
  #       filename = tryFile(basePath, stats)
  #       if !filename and stats and stats.isDirectory()
  #         filename = tryPackage(basePath, exts)
  #       if !filename
  #         # try it with each of the extensions
  #         filename = tryExtensions(basePath, exts)
  #     if !filename
  #       filename = tryPackage(basePath, exts)
  #     if !filename
  #       # try it with each of the extensions at "index"
  #       filename = tryExtensions(path.resolve(basePath, 'index'), exts)
  #     if filename
  #       SandboxModule._pathCache[cacheKey] = filename
  #       return filename
  #     i++
  #   false

  # @_nodeModulePaths = (from) ->
  #   # guarantee that 'from' is absolute.
  #   from = path.resolve(from)
  #   # note: this approach *only* works when the path is guaranteed
  #   # to be absolute.  Doing a fully-edge-case-correct path.split
  #   # that works on both Windows and Posix is non-trivial.
  #   splitRe = if process.platform == 'win32' then /[\/\\]/ else /\//
  #   paths = []
  #   parts = from.split(splitRe)
  #   tip = parts.length - 1
  #   while tip >= 0
  #     # don't search in .../node_modules/node_modules
  #     if parts[tip] == 'node_modules'
  #       tip--
  #       continue
  #     dir = parts.slice(0, tip + 1).concat('node_modules').join(path.sep)
  #     paths.push dir
  #     tip--
  #   paths

  # load: (filename) ->
  #   log.warn 'load filename: ', filename
  #   assert !@loaded
  #   @filename = filename
  #   @paths = SandboxModule._nodeModulePaths path.dirname(filename)
  #   @paths.push path.dirname(filename)
  #   log.warn 'paths', @paths
  #   extension = path.extname(filename) or '.js'
  #   if !SandboxModule._extensions[extension]
  #     extension = '.js'
  #   SandboxModule._extensions[extension] @, filename
  #   @loaded = true


  require: (path) ->
    throw 'SandboxModule#require should be overridden'
    # assert path, 'missing path'
    # assert typeof path is 'string', 'path must be a string'
    # SandboxModule._load path, @


  _compile: (content, filename) ->
    log.debug '_compile: ', filename

    # Create new sandbox context and copy over existing sandbox values
    sandbox = vm.createContext()
    sandbox[k] = v for own k, v of @sandbox
    #log.debug 'sandbox[__dsl] ', sandbox.__dsl
    sandbox.global = sandbox.root = sandbox.GLOBAL = @sandbox
    sandbox.__filename = filename
    sandbox.__dirname  = path.dirname sandbox.__filename
    sandbox.module  = _module  = new SandboxModule 'eval'
    sandbox.require = _require = (path) =>
      SandboxModule._load path, @, true, sandbox
    _module.filename = sandbox.__filename

    # skip = ['paths', 'callee', 'caller', 'arguments']
    # _require[r] = require[r] for r in Object.getOwnPropertyNames require when not _.contains(skip, r)
    # # OR
    _require.main = sandbox.require.mainModule
    _require.extensions = SandboxModule._extensions
    _require.cache = SandboxModule._cache

    # use the same hack node currently uses for their own REPL
    _require.paths = _module.paths = SandboxModule._nodeModulePaths process.cwd()
    _require.resolve = (request) ->
      SandboxModule._resolveFilename request, _module

    wrapper = SandboxModule.wrap content
    compiledWrapper = vm.runInContext wrapper, sandbox, filename: filename

    dirname = path.dirname filename
    self = @
    # Pass in undefined for 'require' argument to prevent loops
    # TODO: debug why setting require to _require causes loop
    # In the meantime, this works but limits sharing of global scope
    # to only one level of require in a task file. Any nested require
    # will end up using Module.require which will share global outside
    # of the VM.
    args = [self.exports, undefined, self, filename, dirname]
    compiledWrapper.apply self.exports, args



#
# HELPERS
#

# statPath = (path) ->
#   try
#     return fs.statSync path
#   catch ex
#     # do nothing
#   return false

# tryPackage = (requestPath, exts) ->
#   pkg = readPackage(requestPath)
#   return false  unless pkg
#   filename = path.resolve(requestPath, pkg)
#   tryFile(filename, null) or tryExtensions(filename, exts) or tryExtensions(path.resolve(filename, 'index'), exts)

# tryFile = (requestPath, stats) ->
#   stats = stats or statPath(requestPath)
#   if stats and !stats.isDirectory()
#     return fs.realpathSync(requestPath, SandboxModule._realpathCache)
#   false

# tryExtensions = (p, exts) ->
#   i = 0
#   EL = exts.length
#   while i < EL
#     filename = tryFile(p + exts[i], null)
#     if filename
#       return filename
#     i++
#   false


# readPackage = (requestPath) ->
#   if Object.hasOwnProperty(packageMainCache, requestPath)
#     return packageMainCache[requestPath]
#   try
#     jsonPath = path.resolve(requestPath, 'package.json')
#     json = fs.readFileSync(jsonPath, 'utf8')
#   catch e
#     return false
#   try
#     pkg = packageMainCache[requestPath] = JSON.parse(json).main
#   catch e
#     e.path = jsonPath
#     e.message = 'Error parsing ' + jsonPath + ': ' + e.message
#     throw e
#   pkg

# packageMainCache = {}
# SandboxModule._realpathCache = {}



module.exports = SandboxModule
