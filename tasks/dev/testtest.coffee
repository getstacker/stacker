# include this file in other task files for testing

console.log '>>>>>>>>>>'
console.log global.__dsl
console.log __filename
console.log '<<<<<<<<<'

global.testtest = testtest = ->
  console.log 'hi from testtest !!!!!'


module.exports = testtest
