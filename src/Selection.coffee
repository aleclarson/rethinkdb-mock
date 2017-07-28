
setType = require "setType"

Selection = require "./Selection"
Datum = require "./Datum"

i = 1
EQ = i++
NE = i++
MERGE = i++
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
DELETE = i++

Selection = (query) ->
  self = (key) -> self._get key
  self._db = query._db
  self._query = query
  return setType self, Selection

methods = Selection.prototype

methods.do = (callback) ->
  return callback this

methods.eq = (value) ->
  @_action = [EQ, value]
  return Datum this

methods.ne = (value) ->
  @_action = [NE, value]
  return Datum this

methods.merge = (values) ->
  @_action = [MERGE, values]
  return Datum this

methods.default = (value) ->
  @_context = {default: value}
  return this

methods.getField = (attr) ->
  @_action = [GET_FIELD, attr]
  return Datum this

methods.without = ->
  @_action = [WITHOUT, arguments]
  return Datum this

methods.pluck = ->
  @_action = [PLUCK, arguments]
  return Datum this

methods.delete = ->
  @_action = [DELETE]
  return Datum this

methods.run = ->
  context = Object.assign {}, @_context
  Promise.resolve()
    .then @_run.bind this, context

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._get = (key) ->
  if typeof key is "string"
  then @getField key
  else @nth key

methods._run = (context) ->
  result = @_query._run context

  unless action = @_action
    return result

  # switch action[0]
  #
  #   when EQ
  #
  #   when NE
  #
  #   when MERGE
  #
  #   when GET_FIELD
  #
  #   when WITHOUT
  #
  #   when PLUCK
  #
  #   when DELETE

module.exports = Selection
