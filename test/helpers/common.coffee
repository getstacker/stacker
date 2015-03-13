require 'stacker-globals'

chai = require 'chai'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
chaiAsPromised = require 'chai-as-promised'

chai.use sinonChai
chai.use chaiAsPromised

module.exports =
  expect: chai.expect
  spy: sinon.spy
  stub: sinon.stub
  sinon: sinon
