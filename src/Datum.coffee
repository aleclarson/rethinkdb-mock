
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

utils = require "./utils"

{isArray} = Array

i = 1
DO = i++
EQ = i++
NE = i++
GT = i++
LT = i++
GE = i++
LE = i++
ADD = i++
SUB = i++
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
MERGE = i++
PLUCK = i++
WITHOUT = i++
REPLACE = i++
UPDATE = i++
DELETE = i++

Datum = (query, action) ->
  self = (key) -> Datum self, [ACCESS, key]
  self._db = query._db
  self._query = query
  self._action = action if action
  return setType self, Datum

methods = Datum.prototype

methods.default = (value) ->
  self = Datum this
  self._context = {default: value}
  return self

methods.do = (callback) ->
  return callback this

methods.eq = (value) ->
  return Datum this, [EQ, value]

methods.ne = (value) ->
  return Datum this, [NE, value]

methods.gt = (value) ->
  return Datum this, [GT, value]

methods.lt = (value) ->
  return Datum this, [LT, value]

methods.ge = (value) ->
  return Datum this, [GE, value]

methods.le = (value) ->
  return Datum this, [LE, value]

methods.add = (value) ->
  return Datum this, [ADD, value]

methods.sub = (value) ->
  return Datum this, [SUB, value]

methods.nth = (value) ->
  return Datum this, [NTH, value]

methods.getField = (value) ->
  return Datum this, [GET_FIELD, value]

methods.hasFields = (value) ->
  return Datum this, [HAS_FIELDS, sliceArray arguments]

methods.offsetsOf = (value) ->
  return Datum this, [OFFSETS_OF, value]

methods.orderBy = (value) ->
  return Datum this, [ORDER_BY, value]

methods.filter = (filter, options) ->
  return Datum this, [FILTER, filter, options]

methods.count = ->
  return Datum this, [COUNT]

methods.limit = (n) ->
  return Datum this, [LIMIT, n]

methods.slice = ->
  return Datum this, [SLICE, sliceArray arguments]

methods.merge = ->
  return Datum this, [MERGE, sliceArray arguments]

methods.without = ->
  return Datum this, [WITHOUT, sliceArray arguments]

methods.pluck = ->
  return Datum this, [PLUCK, sliceArray arguments]

methods.replace = (values) ->
  return Datum this, [REPLACE, values]

# Using a bracket accessor on a sequence
# may result in an array or a row, so
# we're forced to wrap it with `Datum`.
# This means `Datum` must provide the
# `replace`, `update`, and `delete` methods.

methods.replace = (values) ->
  return Datum this, [REPLACE, values]

methods.update = (values) ->
  return Datum this, [UPDATE, values]

# `Sequence::_access(string)` returns a `Datum` for a row.
methods.delete = ->
  return Datum this, [DELETE]

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._run = (context = {}) ->
  Object.assign context, @_context
  result = @_query._run context

  unless action = @_action
    return result

  switch action[0]

    # when EQ
    #
    # when NE
    #
    # when GT
    #
    # when LT
    #
    # when GE
    #
    # when LE
    #
    # when ADD
    #
    # when SUB
    #
    # when NTH

    when ACCESS
      return utils.access result, action[1]

    when GET_FIELD
      return utils.getField result, action[1]

    when HAS_FIELDS
      return utils.hasFields result, action[1]

    when OFFSETS_OF
      assertType result, Array
      return seq.offsetsOf result, action[1]

    when ORDER_BY
      assertType result, Array
      return seq.sort result, action[1]

    when FILTER
      assertType result, Array
      return seq.filter result, action[1], action[2]

    when COUNT
      assertType result, Array
      return result.length

    when LIMIT
      assertType result, Array
      return seq.limit result, action[1]

    when SLICE
      assertType result, Array
      return seq.slice result, action[1]

    when MERGE
      return merge result, action[1]

    when WITHOUT
      if isArray result
        return seq.without result, action[1]
      return utils.without result, action[1]

    when PLUCK
      if isArray result
        return seq.pluck result, action[1]
      return utils.pluck result, action[1]

    # when UPDATE
    #
    # when DELETE

module.exports = Datum

#
# Helpers
#

merge = (result, args) ->

  if isArray result
    return result.map (result) ->
      assertType result, Object
      return utils.merge utils.clone(result), args

  assertType result, Object
  return utils.merge utils.clone(result), args
