
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

utils = require "./utils"

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
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
UPDATE = i++
DELETE = i++

Datum = (query) ->
  self = (key) -> self._get key
  self._db = query._db
  self._query = query
  return setType self, Datum

methods = Datum.prototype

methods.do = (callback) ->
  return callback this

methods.eq = (value) ->
  @_action = [EQ, value]
  return Datum this

methods.ne = (value) ->
  @_action = [NE, value]
  return Datum this

methods.gt = (value) ->
  @_action = [GT, value]
  return Datum this

methods.lt = (value) ->
  @_action = [LT, value]
  return Datum this

methods.ge = (value) ->
  @_action = [GE, value]
  return Datum this

methods.le = (value) ->
  @_action = [LE, value]
  return Datum this

methods.add = (value) ->
  @_action = [ADD, value]
  return Datum this

methods.sub = (value) ->
  @_action = [SUB, value]
  return Datum this

methods.nth = (value) ->
  @_action = [NTH, value]
  return Datum this

methods.count = ->
  @_action = [COUNT]
  return Datum this

methods.merge = ->
  @_action = [MERGE, sliceArray arguments]
  return Datum this

methods.filter = (value, options) ->
  @_action = [FILTER, value, options]
  return Datum this

methods.default = (value) ->
  @_context = {default: value}
  return Datum this

methods.getField = (value) ->
  @_action = [GET_FIELD, value]
  return Datum this

methods.without = ->
  @_action = [WITHOUT, sliceArray arguments]
  return Datum this

methods.pluck = ->
  @_action = [PLUCK, sliceArray arguments]
  return Datum this

# Sequences sometimes return a row wrapped with `Datum`.
methods.update = (values) ->
  @_action = [UPDATE, values]
  return Datum this

# Sequences sometimes return a row wrapped with `Datum`.
methods.delete = ->
  @_action = [DELETE]
  return Datum this

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
    # when MERGE
    #
    # when FILTER

    when GET_FIELD
      return getField result, action[1]

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

getField = (value, attr) ->
  assertType value, Object

  if utils.isQuery attr
    attr = attr._run()

  unless value.hasOwnProperty attr
    throw Error "No attribute `#{attr}` in object"

  return value[attr]
