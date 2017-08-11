# TODO: Support time math with other times or numbers.

arity = require "./arity"
types = require "./types"
utils = require "../utils"

arity.set
  add: arity.ONE_PLUS
  sub: arity.ONE_PLUS
  mul: arity.ONE_PLUS
  div: arity.ONE_PLUS

types.set
  add: types.DATUM
  sub: types.DATUM
  mul: types.DATUM
  div: types.DATUM

actions = exports

# TODO: Support dates and sequences.
actions.add = (result, args) ->
  type = utils.typeOf result
  unless /ARRAY|NUMBER|STRING/.test type
    throw Error "Expected type ARRAY, NUMBER, or STRING but found #{type}"

  total = result
  for arg in args
    utils.expect arg, type
    if type is "ARRAY"
    then total = total.concat arg
    else total += arg

  return total

actions.sub = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total -= arg
  return null

actions.mul = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total *= arg
  return null

actions.div = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total /= arg
  return null
