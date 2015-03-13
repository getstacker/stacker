expect = require('./helpers/Common').expect
log = require 'stacker/log'
tasks = require '../lib/tasks'
path = require 'path'
fs = require 'fs'

describe 'Sandbox', ->

  describe 'require', ->

    checkGlobalLeaks = (prefix) ->
      expect(global["#{prefix}Global"]).to.not.exist
      expect(global["#{prefix}Var"]).to.not.exist
      expect(global["#{prefix}Local"]).to.not.exist

    it  'does not leak globals', (done) ->
      filename = path.resolve __dirname, './fixtures/sandbox/module1.js'
      tasks.load filename
      .then tasks.parse
      .then ->
        checkGlobalLeaks 'mod1'
        checkGlobalLeaks 'mod2'
        checkGlobalLeaks 'mod3'
        expect(String::__testStringExtension__).to.be.undefined
        done()
      .catch done
