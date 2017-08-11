# TODO: Comparison of objects/arrays with `gt`, `lt`, `ge`, `le`

arity = require "./arity"
types = require "./types"
utils = require "../utils"

arity.set
  eq: arity.ONE_PLUS
  ne: arity.ONE_PLUS
  gt: arity.ONE_PLUS
  lt: arity.ONE_PLUS
  ge: arity.ONE_PLUS
  le: arity.ONE_PLUS
  or: arity.ONE_PLUS
  and: arity.ONE_PLUS

types.set
  eq: types.DATUM
  ne: types.DATUM
  gt: types.DATUM
  lt: types.DATUM
  ge: types.DATUM
  le: types.DATUM
  or: types.DATUM
  and: types.DATUM

actions = exports

actions.eq = (result, args) ->
  equals result, args

actions.ne = (result, args) ->
  !equals result, args

actions.gt = (result, args) ->
  prev = result
  for arg in args
    return false if prev <= arg
    prev = arg
  return true

actions.lt = (result, args) ->
  prev = result
  for arg in args
    return false if prev >= arg
    prev = arg
  return true

actions.ge = (result, args) ->
  prev = result
  for arg in args
    return false if prev < arg
    prev = arg
  return true

actions.le = (result, args) ->
  prev = result
  for arg in args
    return false if prev > arg
    prev = arg
  return true

actions.or = (result, args) ->
  return result unless isFalse result
  for arg in args
    return arg unless isFalse arg
  return args.pop()

actions.and = (result, args) ->
  return result if isFalse result
  for arg in args
    return arg if isFalse arg
  return args.pop()

#
# Helpers
#

equals = (result, args) ->
  for arg in args
    return false unless utils.equals result, arg
  return true

isFalse = (value) ->
  (value is null) or (value is false)
