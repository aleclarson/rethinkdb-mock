# TODO: Support time math with other times or numbers.
# TODO: Comparison of objects/arrays with `gt`, `lt`, `ge`, `le`

assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

utils = require "./utils"
row = require "./row"

{isArray} = Array

i = 1
DO = i++
EQ = i++
NE = i++
GT = i++
LT = i++
GE = i++
LE = i++
OR = i++
AND = i++
ADD = i++
SUB = i++
MUL = i++
DIV = i++
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
  query = this
  return Datum
    _db: @_db
    _run: ->
      try result = query._run()
      return result ? value

methods.do = (callback) ->
  utils.do Datum(this), callback

methods.eq = ->
  Datum this, [EQ, sliceArray arguments]

methods.ne = ->
  Datum this, [NE, sliceArray arguments]

methods.gt = ->
  Datum this, [GT, sliceArray arguments]

methods.lt = ->
  Datum this, [LT, sliceArray arguments]

methods.ge = ->
  Datum this, [GE, sliceArray arguments]

methods.le = ->
  Datum this, [LE, sliceArray arguments]

methods.or = ->
  Datum this, [OR, sliceArray arguments]

methods.and = ->
  Datum this, [AND, sliceArray arguments]

methods.add = ->
  Datum this, [ADD, sliceArray arguments]

methods.sub = ->
  Datum this, [SUB, sliceArray arguments]

methods.mul = ->
  Datum this, [MUL, sliceArray arguments]

methods.div = ->
  Datum this, [DIV, sliceArray arguments]

methods.nth = (value) ->
  Datum this, [NTH, value]

methods.getField = (value) ->
  Datum this, [GET_FIELD, value]

methods.hasFields = (value) ->
  Datum this, [HAS_FIELDS, sliceArray arguments]

methods.offsetsOf = (value) ->
  Datum this, [OFFSETS_OF, value]

methods.orderBy = (value) ->
  Datum this, [ORDER_BY, value]

methods.filter = (filter, options) ->
  Datum this, [FILTER, filter, options]

methods.count = ->
  Datum this, [COUNT]

methods.limit = (n) ->
  Datum this, [LIMIT, n]

methods.slice = ->
  Datum this, [SLICE, sliceArray arguments]

methods.merge = ->
  Datum this, [MERGE, sliceArray arguments]

methods.without = ->
  Datum this, [WITHOUT, sliceArray arguments]

methods.pluck = ->
  Datum this, [PLUCK, sliceArray arguments]

# Using a bracket accessor on a sequence
# may result in an array or a row, so
# we're forced to wrap it with `Datum`.
# This means `Datum` must provide the
# `replace`, `update`, and `delete` methods.

methods.replace = (values) ->
  Datum this, [REPLACE, values]

methods.update = (values) ->
  Datum this, [UPDATE, values]

methods.delete = ->
  Datum this, [DELETE]

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

    when EQ
      return equals result, action[1]

    when NE
      return !equals result, action[1]

    when GT
      return greaterThan result, action[1]

    when LT
      return lessThan result, action[1]

    when GE
      return greaterOrEqual result, action[1]

    when LE
      return lessOrEqual result, action[1]

    when OR
      return anyButFalse result, action[1]

    when AND
      return noneFalse result, action[1]

    when ADD
      return add result, action[1]

    when SUB
      return subtract result, action[1]

    when MUL
      return multiply result, action[1]

    when DIV
      return divide result, action[1]

    when NTH
      assertType result, Array
      return seq.nth result, action[1]

    when ACCESS
      if isArray result
        return seq.access result, action[1]
      assertType result, Object
      return utils.getField result, action[1]

    when GET_FIELD
      assertType result, Object
      return utils.getField result, action[1]

    when HAS_FIELDS
      assertType result, Object
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

    when REPLACE
      return null

    when UPDATE
      return null

    when DELETE
      return null

module.exports = Datum

#
# Helpers
#

equals = (result, args) ->
  args = utils.resolve args
  for arg in args
    return no unless utils.equals result, arg
  return yes

greaterThan = (result, args) ->
  args = utils.resolve args
  prev = result
  for arg in args
    return no if prev <= arg
    prev = arg
  return yes

lessThan = (result, args) ->
  args = utils.resolve args
  prev = result
  for arg in args
    return no if prev >= arg
    prev = arg
  return yes

greaterOrEqual = (result, args) ->
  args = utils.resolve args
  prev = result
  for arg in args
    return no if prev < arg
    prev = arg
  return yes

lessOrEqual = (result, args) ->
  args = utils.resolve args
  prev = result
  for arg in args
    return no if prev > arg
    prev = arg
  return yes

anyButFalse = (result, args) ->
  args = utils.resolve args
  return result if result isnt no
  for arg in args
    return arg if arg isnt no
  return no

noneFalse = (result, args) ->
  args = utils.resolve args
  return no if result is no
  for arg in args
    return no if arg is no
  return args.pop()

add = (result, args) ->
  assertType result, Number
  args = utils.resolve args
  total = result
  for arg in args
    assertType arg, Number
    total += arg
  return total

subtract = (result, args) ->
  assertType result, Number
  args = utils.resolve args
  total = result
  for arg in args
    assertType arg, Number
    total -= arg
  return null

multiply = (result, args) ->
  assertType result, Number
  args = utils.resolve args
  total = result
  for arg in args
    assertType arg, Number
    total *= arg
  return null

divide = (result, args) ->
  assertType result, Number
  args = utils.resolve args
  total = result
  for arg in args
    assertType arg, Number
    total /= arg
  return null

merge = (result, args) ->
  args = utils.resolve args

  unless isArray result
    return utils.merge result, args

  return result.map (result) ->
    return utils.merge result, args
