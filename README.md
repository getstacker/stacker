# Stacker: Extensible DevOps Toolbelt


# Install

Review [install script](https://github.com/getstacker/stacker/blob/master/install), then...

```bash
curl -s https://raw.githubusercontent.com/getstacker/stacker/master/install | sh -e
```

# Plugins

Stacker plugins are NPM modules.


## Developing a Plugin

Use `npm link` to add your work-in-progress plugin to stacker.

```bash
# Create the plugin directory
mkdir my-new-plugin
cd my-new-plugin

# Setup the package.json file
npm init

# Link the current directory into npm's global node_modules so stacker can find it
npm link

# Add the new plugin link to stacker
stacker link my-new-plugin
```


# API

- https://github.com/gulpjs/gulp/blob/master/docs/API.md
- https://github.com/gulpjs/gulp/tree/master/docs/recipes



# TODO

- setup gulp processor with global injection for task, sh, etc

- setup config parsing with stacker header support
  - parse all *.stack files in project by default
  - if no header, output file in same dir without the .stack extension

- add support for injecting common header in output conf file
  - support ini, bash/sh, coffeescript/javascript, ruby, etc. types ...
  - or support comment syntax setting in .stack header

- create official DSL support with [jison](http://zaach.github.io/jison/docs/)


# Credits

Stacker logo (Squares) designed by [Nicholas Menghini](http://www.thenounproject.com/nl_menghini) from the [Noun Project](http://www.thenounproject.com).
