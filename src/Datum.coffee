
assertType = require "assertType"
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
MERGE = i++
FILTER = i++
DEFAULT = i++
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
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

methods.merge = (values) ->
  @_action = [MERGE, values]
  return Datum this

methods.filter = (value, options) ->


methods.default = (value) ->
  @_context = {default: value}
  return Datum this

methods.getField = ->

methods.without = ->

methods.pluck = ->

# NOTE: This is required because sequence(0) returns a `Datum` instance.
methods.delete = ->

methods.run = ->
  context = Object.assign {}, @_context
  Promise.resolve()
    .then @_run.bind this, context

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._run = (context) ->
  result = @_query._run context

  unless action = @_action
    return result

  switch action[0]

    when GET_FIELD
      return getField result, action[1]

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
