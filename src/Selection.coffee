
setType = require "setType"

Selection = require "./Selection"

i = 1
DO = i++
EQ = i++
NE = i++
MERGE = i++
DEFAULT = i++
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
DELETE = i++

Selection = (query) ->
  self = (key) -> self._get key
  self._query = query
  self._action = null
  return setType self, Selection

methods = Selection.prototype

methods.delete = ->
  @_actions.push [DELETE]
  return this

# do ->
#   actions =
#     getField: GET_FIELD
#     default: DEFAULT
#     do: DO
#     eq: EQ
#     ne: NE
#   Object.keys(actions).forEach (key) ->
#     actionId = actions[key]
#     methods[key] = (value) ->
#       @_actions.push [actionId, value]
#       return this
#
# do ->
#   actions =
#     pluck: PLUCK
#     without: WITHOUT
#     merge: MERGE
#   Object.keys(actions).forEach (key) ->
#     actionId = actions[key]
#     methods[key] = ->
#       @_actions.push [actionId, arguments]
#       return this

methods.run = ->
  return @_root.run() if @_root
  throw Error "Cannot call `run` in this context"

methods._get = (key) ->
  if typeof key is "string"
  then @getField key
  else @nth key

methods._run = (data) ->

module.exports = Selection
