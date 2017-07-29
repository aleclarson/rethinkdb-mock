
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Selection = require "./Selection"
Datum = require "./Datum"
utils = require "./utils"

i = 1
EQ = i++
NE = i++
MERGE = i++
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
UPDATE = i++
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

methods.merge = ->
  @_action = [MERGE, sliceArray arguments]
  return Datum this

methods.default = (value) ->
  @_context = {default: value}
  return this

methods.getField = (attr) ->
  @_action = [GET_FIELD, attr]
  return Datum this

methods.without = ->
  @_action = [WITHOUT, sliceArray arguments]
  return Datum this

methods.pluck = ->
  @_action = [PLUCK, sliceArray arguments]
  return Datum this

methods.update = (values) ->
  @_action = [UPDATE, values]
  return Datum this

methods.delete = ->
  @_action = [DELETE]
  return Datum this

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._get = (key) ->
  if typeof key is "string"
  then @getField key
  else @nth key

methods._run = (context = {}) ->
  Object.assign context, @_context
  result = @_query._run context

  unless action = @_action
    return result

  switch action[0]
  #
  #   when EQ
  #
  #   when NE
  #
  #   when MERGE
  #
  #   when GET_FIELD

    when WITHOUT
      return utils.without result, action[1]

    when PLUCK
      return utils.pluck result, action[1]

    when UPDATE
      return updateRow result, action[1]

    when DELETE
      return deleteRow @_db, context.tableId, result

module.exports = Selection

#
# Helpers
#

updateRow = (row, values) ->

  unless row
    return {skipped: 1}

  if utils.isQuery values
    values = values._run()

  # TODO: Track if the row is not modified.
  utils.merge row, values
  return {updated: 1}

deleteRow = (db, tableId, row) ->
  assertType tableId, String

  unless row
    return {skipped: 1}

  table = db._tables[tableId]
  index = table.indexOf row
  table.splice index, 1
  return {deleted: 1}
