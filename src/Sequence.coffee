# TODO: Support `offsetsOf` function argument
# TODO: Support `orderBy` function argument

assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Selection = require "./Selection"
Datum = require "./Datum"
utils = require "./utils"
seq = require "./utils/sequence"

i = 1
GET = i++
NTH = i++
GET_FIELD = i++
OFFSETS_OF = i++
UPDATE = i++
FILTER = i++
ORDER_BY = i++
LIMIT = i++
SLICE = i++
PLUCK = i++
WITHOUT = i++
FOLD = i++
DELETE = i++

Sequence = (query) ->
  self = (value) -> self._get value
  self._db = query._db
  self._query = query
  return setType self, Sequence

methods = Sequence.prototype

methods.do = (callback) ->
  return callback this

methods.nth = (index) ->
  @_action = [NTH, index]
  return Selection this

methods.getField = (attr) ->
  @_action = [GET_FIELD, attr]
  return Sequence this

methods.offsetsOf = (value) ->
  @_action = [OFFSETS_OF, value]
  return Datum this

methods.update = (value, options) ->
  @_action = [UPDATE, value, options]
  return Datum this

methods.filter = (value, options) ->
  @_action = [FILTER, value, options]
  return Sequence this

methods.orderBy = ->
  @_action = [ORDER_BY, sliceArray arguments]
  return Sequence this

methods.limit = (n) ->
  @_action = [LIMIT, n]
  return Sequence this

methods.slice = ->
  @_action = [SLICE, sliceArray arguments]
  return Sequence this

methods.pluck = ->
  @_action = [PLUCK, sliceArray arguments]
  return Sequence this

methods.without = ->
  @_action = [WITHOUT, sliceArray arguments]
  return Sequence this

methods.fold = (value, iterator) ->
  @_action = [FOLD, value, iterator]
  return Datum this

methods.delete = ->
  @_action = [DELETE]
  return Datum this

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._get = (value) ->
  @_action = [GET, value]
  return Sequence this

methods._run = (context = {}) ->
  Object.assign context, @_context
  rows = @_query._run context
  assertType rows, Array

  unless action = @_action
    return rows

  switch action[0]

    when GET
      return seq.access rows, action[1]

    # when NTH
    #
    # when GET_FIELD
    #
    # when OFFSETS_OF

    when UPDATE
      return updateRows rows, action[1], action[2]

    when FILTER
      return seq.filter rows, action[1]

    when ORDER_BY
      return seq.sort rows, action[1]

    when LIMIT
      return seq.limit rows, action[1]

    when SLICE
      return seq.slice rows, action[1]
    #
    # when PLUCK
    #
    # when WITHOUT
    #
    # when FOLD

    when DELETE
      return deleteRows @_db, context.tableId, rows

module.exports = Sequence

#
# Helpers
#

updateRows = (rows, patch, options) ->
  # TODO: Throw an error if not an array of rows.

  if utils.isQuery patch
    patch = patch._run()

  if utils.isQuery options
    options = options._run()

  options ?= {}

  assertType patch, Object
  assertType options, Object

  # TODO: Track which rows are not modified.
  for row in rows
    utils.merge row, patch

  return {replaced: rows.length}

deleteRows = (db, tableId, rows) ->
  assertType tableId, String
  # TODO: Throw an error if not an array of rows.

  count = 0
  table = db._tables[tableId]
  table = table.filter (row) ->
    if ~rows.indexOf row
      count += 1
      return no
    return yes

  db._tables[tableId] = table
  return {deleted: count}
