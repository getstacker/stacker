# !!! THIS PROJECT IS WIP AND NOT YET READY FOR PUBLIC USE !!!

[![Join the chat at https://gitter.im/getstacker/stacker](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/getstacker/stacker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


# Stacker: Extensible DevOps Toolbelt

Stacker is a flexible task runner with built-in configuration templating and plugin support.

It's compatible with gulp plugins.

Gulp is comprised of two core components:
1. [orchestrator](https://github.com/orchestrator/orchestrator) for running tasks concurrently
2. [vinyl-fs](https://github.com/wearefractal/vinyl-fs) for globbing and piping files


# Install

Install via npm or install script.

The preferred method is the install script. This is similar to [brew](http://brew.sh/) where
the install script clones the main git repo.

### Install Script

Review [install script](https://github.com/getstacker/stacker/blob/master/install), then...

```bash
sh -e <(curl -sS --tlsv1.2 https://raw.githubusercontent.com/getstacker/stacker/master/install)
```

Installation may take awhile and appear to freeze while installing npm modules.
This is due to a bug in npm 2.0.0 when using npm-shrinkwrap. The install script
should eventually complete even with the `npm ERR! cb()` error.


### NPM

It's recommended to use the install script.

```bash
npm install -g stacker
```


### Common Install Errors

```bash
...
flags for v8 3.26.33 cached.
npm ERR! cb() never called!
```

[StackOverflow thread](http://stackoverflow.com/questions/15393821/npm-err-cb-never-called) and
[Github issue](https://github.com/npm/npm/issues/5920)

There's a bug in npm that should be fixed in 2.0.2. Rerunning the install script fixes the issues.

# Uninstall

```bash
curl -sS --tlsv1.2 https://raw.githubusercontent.com/getstacker/stacker/master/uninstall | sh -e
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
- https://github.com/osscafe/gulp-cheatsheet

# DESIGN GOALS

- devops focused task runner
- simple but expressive DSL for writing scripts
  - better than bash
  - all the power of node and npm modules
  - highly testable
- pipes and promises
- not a replacement for ansible or salt
  - much smaller in scope
  - can run ansible or salt commands
- primarily acts as a developer api
  - wraps other programs
  - simplifies chaining a bunch of programs together

# CORE CONCEPTS

### Context

Stacker runs tasks in VMs and containers. For security reasons, it does not
run anything on the host by default except for core stacker CLI commands.

Context is defined as a colon separated string: "VM:CONTAINER".

```
"*:*" means run in all VMs and all containers
"-:*" means run in all containers on all VMs but do not run in the VM itself
"*:-" means run in all VMs but not in containers
"/vm-remote-.*/:/*._database/" means run in all VMs and containers matching the regexes
```

### Runners

Runners are defined in plugins. They are functions that register with stacker
to run commands in different contexts.


### Config

Stacker can parse json and yml config files with optional stacker templating.

### Tasks

Tasks are defined within plugins or within a specific project. Task files are
similar in concept to rake or make files. They're scripts that define tasks
and dependencies.

### Logging



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
