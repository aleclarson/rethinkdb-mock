
isConstructor = require "isConstructor"

arity = require "./arity"
types = require "./types"
utils = require "../utils"
seq = require "../utils/seq"

seqRE = /TABLE|SELECTION<ARRAY>/

arity.set
  bracket: arity.ONE
  getField: arity.ONE
  hasFields: arity.ONE_PLUS
  merge: arity.ONE_PLUS
  pluck: arity.ONE_PLUS
  without: arity.ONE_PLUS

types.set
  bracket: types.BRACKET
  getField: types.DATUM
  hasFields: types.SEQUENCE
  merge: types.DATUM
  pluck: types.DATUM
  without: types.DATUM

actions = exports

actions.bracket = (result, key) ->
  type = utils.typeOf key

  if type is "NUMBER"

    if key < -1 and seqRE.test @type
      throw Error "Cannot use an index < -1 on a stream"

    return seq.nth result, key

  if type isnt "STRING"
    throw Error "Expected NUMBER or STRING as second argument to `bracket` but found #{type}"

  type = utils.typeOf result

  if type is "ARRAY"
    return seq.getField result, key

  if type is "OBJECT"
    return utils.getField result, key

  throw Error "Expected ARRAY or OBJECT as first argument to `bracket` but found #{type}"

actions.getField = (result, attr) ->
  utils.expect attr, "STRING"

  type = utils.typeOf result

  if type is "ARRAY"
    return seq.getField result, attr

  if type is "OBJECT"
    return utils.getField result, attr

  throw Error "Expected ARRAY or OBJECT but found #{type}"

# TODO: Support key map validation.
actions.hasFields = (result, attrs) ->
  attrs = utils.flatten attrs

  for attr in attrs
    utils.expect attr, "STRING"

  type = utils.typeOf result

  if type is "ARRAY"
    return seq.hasFields result, attrs

  if type is "OBJECT"
    return utils.hasFields result, attrs

  throw Error "Expected ARRAY or OBJECT but found #{type}"

actions.merge = (result, args) ->
  type = utils.typeOf result

  if type is "ARRAY"
    return result.map (row) ->
      utils.expect row, "OBJECT"
      mergeObjects row, args

  if type is "OBJECT"
    return mergeObjects result, args

  throw Error "Expected ARRAY or OBJECT but found #{type}"

actions.pluck = (result, args) ->
  type = utils.typeOf result

  if type is "ARRAY"
    return seq.pluck result, args

  if type is "OBJECT"
    return utils.pluck result, args

  throw Error "Expected ARRAY or OBJECT but found #{type}"

actions.without = (result, args) ->
  args = utils.flatten args
  type = utils.typeOf result

  if type is "ARRAY"
    return seq.without result, args

  if type is "OBJECT"
    return utils.without result, args

  throw Error "Expected ARRAY or OBJECT but found #{type}"

#
# Helpers
#

mergeObjects = (output, inputs) ->
  output = utils.cloneObject output
  ctx = {row: output}
  for input in inputs
    if utils.isQuery input
      input = input._eval ctx
    output = merge output, input
  return output

# NOTE: Nested queries must be resolved before calling this function.
merge = (output, input) ->

  # Non-objects overwrite the output.
  return input unless isConstructor input, Object

  # Nothing to merge into.
  return input unless isConstructor output, Object

  for key, value of input
    if isConstructor value, Object
      if isConstructor output[key], Object
      then merge output[key], value
      else output[key] = value
    else output[key] = value

  return output
