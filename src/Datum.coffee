# TODO: Support time math with other times or numbers.
# TODO: Comparison of objects/arrays with `gt`, `lt`, `ge`, `le`

sliceArray = require "sliceArray"
setType = require "setType"

utils = require "./utils"
row = require "./utils/row"
seq = require "./utils/seq"

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
  utils.default Datum(this), value

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
      return stopAtNotFalse result, action[1]

    when AND
      return stopAtFalse result, action[1]

    when ADD
      return add result, action[1]

    when SUB
      return subtract result, action[1]

    when MUL
      return multiply result, action[1]

    when DIV
      return divide result, action[1]

    when NTH
      utils.expectArray result
      return seq.nth result, action[1]

    when ACCESS
      return access result, action[1]

    when GET_FIELD
      utils.expect result, "OBJECT"
      return utils.getField result, action[1]

    when HAS_FIELDS
      utils.expect result, "OBJECT"
      return utils.hasFields result, action[1]

    when OFFSETS_OF
      utils.expectArray result
      return seq.offsetsOf result, action[1]

    when ORDER_BY
      utils.expectArray result
      return seq.sort result, action[1]

    when FILTER
      utils.expectArray result
      return seq.filter result, action[1], action[2]

    when COUNT
      utils.expectArray result
      return result.length

    when LIMIT
      utils.expectArray result
      return seq.limit result, action[1]

    when SLICE
      return slice result, action[1]

    when MERGE
      return merge result, action[1]

    when WITHOUT
      return without result, action[1]

    when PLUCK
      return pluck result, action[1]

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

isFalse = (value) ->
  (value is null) or (value is false)

stopAtNotFalse = (result, args) ->
  args = utils.resolve args
  return result unless isFalse result
  for arg in args
    return arg unless isFalse arg
  return args.pop()

stopAtFalse = (result, args) ->
  args = utils.resolve args
  return result if isFalse result
  for arg in args
    return arg if isFalse arg
  return args.pop()

add = (result, args) ->
  utils.expect result, "NUMBER"
  args = utils.resolve args
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total += arg
  return total

subtract = (result, args) ->
  utils.expect result, "NUMBER"
  args = utils.resolve args
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total -= arg
  return null

multiply = (result, args) ->
  utils.expect result, "NUMBER"
  args = utils.resolve args
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total *= arg
  return null

divide = (result, args) ->
  utils.expect result, "NUMBER"
  args = utils.resolve args
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total /= arg
  return null

access = (result, key) ->

  if utils.isQuery key
    key = key._run()

  keyType = utils.typeOf key
  if keyType is "NUMBER"
    utils.expectArray result
    return seq.nth result, key

  if keyType isnt "STRING"
    throw Error "Expected NUMBER or STRING as second argument to `bracket` but found #{keyType}"

  resultType = utils.typeOf result
  if resultType is "ARRAY"
    return seq.access result, key

  if resultType is "OBJECT"
    return utils.getField result, key

  throw Error "Expected ARRAY or OBJECT as first argument to `bracket` but found #{resultType}"

slice = (result, args) ->

  resultType = utils.typeOf result
  if resultType is "ARRAY"
    return seq.slice result, action[1]

  if resultType is "BINARY"
    throw Error "`slice` does not support BINARY values (yet)"

  if resultType is "STRING"
    throw Error "`slice` does not support STRING values (yet)"

  throw Error "Expected ARRAY, BINARY, or STRING, but found #{resultType}"

merge = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "OBJECT"
    return utils.merge result, utils.resolve args

  if resultType is "ARRAY"
    return seq.merge result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

without = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "OBJECT"
    return utils.without result, utils.resolve args

  if resultType is "ARRAY"
    return seq.without result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

pluck = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "OBJECT"
    return utils.pluck result, utils.resolve args

  if resultType is "ARRAY"
    return seq.pluck result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"
