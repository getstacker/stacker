var mod3 = require('./module3');

global.mod2Global = 'mod2Global';
var mod2Var = 'mod2Var';
mod2Local = 'mod2Local';

String.prototype.__testStringExtension__ = function() {
  return 'module2'
};

module.exports = {
  mod2: 'mod2'
};
