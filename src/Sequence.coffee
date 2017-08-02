
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Selection = require "./Selection"
Datum = require "./Datum"
utils = require "./utils"
seq = require "./utils/seq"

i = 1
NTH = i++
ACCESS = i++
GET_FIELD = i++
HAS_FIELDS = i++
OFFSETS_OF = i++
ORDER_BY = i++
FILTER = i++
COUNT = i++
LIMIT = i++
SLICE = i++
PLUCK = i++
WITHOUT = i++
FOLD = i++
UPDATE = i++
DELETE = i++

Sequence = (query, action) ->
  self = (key) -> self._access key
  self._db = query._db
  self._query = query
  self._action = action if action
  return setType self, Sequence

methods = Sequence.prototype

methods.do = (callback) ->
  throw Error "Sequences must be coerced to arrays before calling `do`"

methods.nth = (index) ->
  Selection Sequence this, [NTH, index]

methods.getField = (attr) ->
  Sequence this, [GET_FIELD, attr]

methods.hasFields = ->
  Sequence this, [HAS_FIELDS, sliceArray arguments]

methods.offsetsOf = (value) ->
  Datum Sequence this, [OFFSETS_OF, value]

methods.orderBy = (value) ->
  Sequence this, [ORDER_BY, value]

methods.filter = (filter, options) ->
  Sequence this, [FILTER, filter, options]

methods.count = ->
  Datum Sequence this, [COUNT]

methods.limit = (n) ->
  Sequence this, [LIMIT, n]

methods.slice = ->
  Sequence this, [SLICE, sliceArray arguments]

methods.pluck = ->
  Sequence this, [PLUCK, sliceArray arguments]

methods.without = ->
  Sequence this, [WITHOUT, sliceArray arguments]

methods.fold = (value, iterator) ->
  Datum Sequence this, [FOLD, value, iterator]

methods.update = (value, options) ->
  Datum Sequence this, [UPDATE, value, options]

methods.delete = ->
  Datum Sequence this, [DELETE]

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._access = (key) ->
  Datum Sequence this, [ACCESS, key]

methods._run = (context = {}) ->
  Object.assign context, @_context
  rows = @_query._run context
  assertType rows, Array

  unless action = @_action
    return rows

  switch action[0]

    when NTH
      return seq.nth rows, action[1]

    when ACCESS
      return seq.access rows, action[1]

    when GET_FIELD
      return seq.getField rows, action[1]

    when HAS_FIELDS
      return seq.hasFields rows, action[1]

    when OFFSETS_OF
      return seq.offsetsOf rows, action[1]

    when FILTER
      return seq.filter rows, action[1], action[2]

    when ORDER_BY
      return seq.sort rows, action[1]

    when COUNT
      return rows.length

    when LIMIT
      return seq.limit rows, action[1]

    when SLICE
      return seq.slice rows, action[1]

    when PLUCK
      return seq.pluck rows, action[1]

    when WITHOUT
      return seq.without rows, action[1]

    when FOLD
      return null # TODO: Implement `fold`

    when UPDATE
      return updateRows rows, action[1], action[2]

    when DELETE
      return deleteRows @_db, context.tableId, rows

module.exports = Sequence

#
# Helpers
#

updateRows = (rows, values, options) ->
  # TODO: Throw an error if not an array of rows.

  if utils.isQuery values
    values = values._run()
    assertType values, Object

  else
    assertType values, Object
    values = utils.resolve values

  if utils.isQuery options
    options = options._run()
    assertType options, Object

  else if options?
    assertType options, Object
    options = utils.resolve options

  else options = {}

  replaced = 0
  for row in rows
    if utils.update row, values
      replaced += 1

  return {replaced, unchanged: rows.length - replaced}

deleteRows = (db, tableId, rows) ->
  assertType tableId, String
  # TODO: Throw an error if not an array of rows.

  deleted = 0
  db._tables[tableId] =
    db._tables[tableId].filter (row) ->
      if ~rows.indexOf row
        deleted += 1
        return no
      return yes

  return {deleted}
