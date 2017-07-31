
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
COUNT = i++
MERGE = i++
FILTER = i++
ACCESS = i++
GET_FIELD = i++
HAS_FIELDS = i++
WITHOUT = i++
PLUCK = i++
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

methods.count = ->
  return Datum this, [COUNT]

methods.merge = ->
  return Datum this, [MERGE, sliceArray arguments]

methods.filter = (value, options) ->
  return Datum this, [FILTER, value, options]

methods.default = (value) ->
  self = Datum this
  self._context = {default: value}
  return self

methods.getField = (value) ->
  return Datum this, [GET_FIELD, value]

methods.hasFields = (value) ->
  return Datum this, [HAS_FIELDS, sliceArray arguments]

methods.without = ->
  return Datum this, [WITHOUT, sliceArray arguments]

methods.pluck = ->
  return Datum this, [PLUCK, sliceArray arguments]

methods.replace = (values) ->
  return Datum this, [REPLACE, values]

# Sequences sometimes return a row wrapped with `Datum`.
methods.update = (values) ->
  return Datum this, [UPDATE, values]

# Sequences sometimes return a row wrapped with `Datum`.
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
    #
    # when COUNT
    #
    when MERGE
      return merge result, action[1]
    #
    # when FILTER
    #
    # when NTH

    when ACCESS
      return utils.access result, action[1]

    when GET_FIELD
      return utils.getField result, action[1]

    when HAS_FIELDS
      return utils.hasFields result, action[1]

    # when WITHOUT
    #
    # when PLUCK
    #
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
