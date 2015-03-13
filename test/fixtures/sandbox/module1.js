var mod2 = require('./module2');

global.mod1Global = 'mod1Global';
var mod1Var = 'mod1Var';
mod1Local = 'mod1Local';

if (typeof ''.__testStringExtension__ !== 'function' || ''.__testStringExtension__() !== 'module2')
  throw 'String extension not set';

module.exports = {
  mod1: 'mod1'
};
