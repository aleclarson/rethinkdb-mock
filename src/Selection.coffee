
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
  utils.default Datum(this), value

methods.do = (callback) ->
  utils.do Selection(@_query), callback

methods.eq = ->
  Datum Selection @_query, [EQ, sliceArray arguments]

methods.ne = ->
  Datum Selection @_query, [NE, sliceArray arguments]

methods.getField = (attr) ->
  Datum Selection @_query, [GET_FIELD, attr]

methods.hasFields = ->
  Datum Selection @_query, [HAS_FIELDS, sliceArray arguments]

methods.merge = ->
  Datum Selection @_query, [MERGE, sliceArray arguments]

methods.without = ->
  Datum Selection @_query, [WITHOUT, sliceArray arguments]

methods.pluck = ->
  Datum Selection @_query, [PLUCK, sliceArray arguments]

methods.replace = (values) ->
  Datum Selection @_query, [REPLACE, values]

methods.update = (values) ->
  Datum Selection @_query, [UPDATE, values]

methods.delete = ->
  Datum Selection @_query, [DELETE]

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._access = (attr) ->
  Datum Selection @_query, [GET_FIELD, attr]

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
      utils.expect result, "OBJECT"
      return utils.merge result, utils.resolve action[1]

    when GET_FIELD
      utils.expect result, "OBJECT"
      return utils.getField result, action[1]

    when HAS_FIELDS
      utils.expect result, "OBJECT"
      return utils.hasFields result, action[1]

    when WITHOUT
      utils.expect result, "OBJECT"
      return utils.without result, action[1]

    when PLUCK
      utils.expect result, "OBJECT"
      return utils.pluck result, action[1]

    when REPLACE
      return row.replace @_db, context, result, action[1]

    when UPDATE
      return row.update result, action[1]

    when DELETE
      return row.delete @_db, context.tableId, result

module.exports = Selection
