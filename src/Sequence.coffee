# TODO: Support `offsetsOf` function argument
# TODO: Support `orderBy` function argument

assertType = require "assertType"
setType = require "setType"
isType = require "isType"

Selection = require "./Selection"
tables = require "./tables"
Datum = require "./Datum"

i = 1
DO = i++
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
  self._query = query
  self._action = null
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
  @_action = [ORDER_BY, arguments]
  return Sequence this

methods.limit = (n) ->
  @_action = [LIMIT, n]
  return Sequence this

methods.slice = ->
  @_action = [SLICE, arguments]
  return Sequence this

methods.pluck = ->
  @_action = [PLUCK, arguments]
  return Sequence this

methods.without = ->
  @_action = [WITHOUT, arguments]
  return Sequence this

methods.fold = (value, iterator) ->
  @_action = [FOLD, value, iterator]
  return Datum this

methods.delete = ->
  @_action = [DELETE]
  return Datum this

methods.run = ->
  Promise.try => @_run()

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._get = (value) ->
  @_action = [GET, value]
  return Sequence this

methods._getTable = ->
  query = @_query
  while !query._tableId
    query = query._query
  return query._tableId

methods._run = ->
  array = @_query._run()
  assertType array, Array

  unless action = @_action
    return array

  switch action[0]

    # when DO
    #
    # when GET
    #
    # when NTH
    #
    # when GET_FIELD
    #
    # when OFFSETS_OF
    #
    # when UPDATE
    #
    # when FILTER

    when ORDER_BY
      return orderBy array, action[1]

    # when LIMIT
    #
    # when SLICE
    #
    # when PLUCK
    #
    # when WITHOUT
    #
    # when FOLD

    when DELETE
      return deleteRows @_getTable(), array

module.exports = Sequence

#
# Helpers
#

orderBy = (array, args) ->
  # TODO: Check for args[1].index

  if isType args[0], Array
    descending = args[0][0] is "desc"
    key = args[0][1]

  else if isType args[0], String
    key = args[0]

  assertType key, String
  return array.slice().sort (a, b) ->
    # TODO: Implement sorting

deleteRows = (tableId, rows) ->

  count = 0
  table = tables.get tableId
  table = table.filter (row) ->
    if ~rows.indexOf row
      count += 1
      return no
    return yes

  tables.set tableId, table
  return {deleted: count}
