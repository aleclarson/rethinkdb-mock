
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Selection = require "./Selection"
Datum = require "./Datum"
utils = require "./utils"
row = require "./utils/row"

i = 1
EQ = i++
NE = i++
MERGE = i++
GET_FIELD = i++
HAS_FIELDS = i++
WITHOUT = i++
PLUCK = i++
REPLACE = i++
UPDATE = i++
DELETE = i++

Selection = (query, action) ->
  self = (attr) -> self._access attr
  self._db = query._db
  self._query = query
  self._action = action if action
  return setType self, Selection

methods = Selection.prototype

methods.default = (value) ->
  self = Datum this
  self._context = {default: value}
  return self

methods.do = (callback) ->
  return callback this

methods.eq = (value) ->
  self = Selection @_query, [EQ, value]
  return Datum self

methods.ne = (value) ->
  self = Selection @_query, [NE, value]
  return Datum self

methods.getField = (attr) ->
  self = Selection @_query, [GET_FIELD, attr]
  return Datum self

methods.hasFields = ->
  self = Selection @_query, [HAS_FIELDS, sliceArray arguments]
  return Datum self

methods.merge = ->
  self = Selection @_query, [MERGE, sliceArray arguments]
  return Datum self

methods.without = ->
  self = Selection @_query, [WITHOUT, sliceArray arguments]
  return Datum self

methods.pluck = ->
  self = Selection @_query, [PLUCK, sliceArray arguments]
  return Datum self

methods.replace = (values) ->
  self = Selection @_query, [REPLACE, values]
  return Datum self

methods.update = (values) ->
  self = Selection @_query, [UPDATE, values]
  return Datum self

methods.delete = ->
  self = Selection @_query, [DELETE]
  return Datum self

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._access = (attr) ->
  self = Selection @_query, [GET_FIELD, attr]
  return Datum self

methods._run = (context = {}) ->
  Object.assign context, @_context
  result = @_query._run context

  unless action = @_action
    return utils.clone result

  switch action[0]

    when EQ
      return utils.equals result, action[1]

    when NE
      return !utils.equals result, action[1]

    when MERGE
      return utils.merge utils.clone(result), action[1]

    when GET_FIELD
      return utils.getField result, action[1]

    when HAS_FIELDS
      return utils.hasFields result, action[1]

    when WITHOUT
      return utils.without result, action[1]

    when PLUCK
      return utils.pluck result, action[1]

    when REPLACE
      return row.replace @_db, context.tableId, result.id, action[1]

    when UPDATE
      return row.update result, action[1]

    when DELETE
      return row.delete @_db, context.tableId, result

module.exports = Selection
