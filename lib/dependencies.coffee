

# Check that each dependency in the list is present in .stacker/package.json
check = (list) ->
  # 1. check if ./.stacker/package.json exists
  # 2. make sure each dependency in the list is in package.json
  # 3. return true or false
  true

install = (list) ->
  # 1. add each dependency in the list to stacker/package.json
  # 2. run `cd ./.stacker && npm install`

module.exports =
  check: check
