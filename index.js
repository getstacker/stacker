var path = require('path');
if (process.env.NODE_PATH) {
  process.env.NODE_PATH = __dirname + path.delimiter + process.env.NODE_PATH;
} else {
  process.env.NODE_PATH = __dirname;
}

require('coffee-script/register');
require('stacker-globals');
require('./lib/runner').run();
