# Utilities for sequences

isConstructor = require "isConstructor"
assertType = require "assertType"

utils = require "."

{isArray} = Array

seq = exports

seq.bracket = (array, value) ->

  if isConstructor value, Number
    return seq.nth array, value

  if isConstructor value, String
    return seq.getField array, value

  throw Error "Expected a Number or String!"

# TODO: Prevent indexes less than -1 for streams.
seq.nth = (array, index) ->
  utils.expectArray array

  assertType index, Number

  if index < 0
    index = array.length + index

  if index < 0 or index >= array.length
    throw RangeError "Index out of bounds"

  return array[index]

seq.getField = (array, attr) ->
  utils.expect attr, "STRING"

  results = []
  for value in array
    assertType value, Object
    if value.hasOwnProperty attr
      results.push value[attr]

  return results

seq.hasFields = (array, attrs) ->

  for attr in attrs
    utils.expect attr, "STRING"

  results = []
  for value in array
    utils.expect value, "OBJECT"
    if hasFields value, attrs
      results.push value

  return results

seq.filter = (array, filter, options) ->

  if options isnt undefined
    assertType options, Object
    # TODO: Support `default` option
    # TODO: Support sub-queries in the `options` object.

  matchers = []
  if isConstructor filter, Object

    matchers.push (values) ->
      assertType values, Object
      return yes

    Object.keys(filter).forEach (key) ->
      matchers.push (values) ->
        utils.equals values[key], filter[key]

  # TODO: Support function argument
  else if isConstructor filter, Function
    throw Error "Filter functions are not implemented yet"

  # The native API returns the sequence when
  # the filter is neither an object nor function.
  else return array.slice()

  return array.filter (row) ->
    for matcher in matchers
      return no unless matcher row
    return yes

# TODO: Throw error for negative indexes on a "stream".
seq.slice = (array, args) ->

  options =
    if isConstructor args[args.length - 1], Object
    then args.pop()
    else {}

  [startIndex, endIndex] = args
  endIndex ?= array.length

  assertType startIndex, Number
  assertType endIndex, Number

  if options.leftBound is "open"
    startIndex += 1

  if options.rightBound is "closed"
    endIndex += 1

  return array.slice startIndex, endIndex

seq.merge = (rows, args) ->
  rows.map (row) ->
    utils.merge row, args

seq.pluck = (rows, args) ->
  rows.map (row) ->
    utils.pluck row, args

seq.without = (rows, args) ->
  rows.map (row) ->
    utils.without row, args

#
# Helpers
#

hasFields = (value, attrs) ->
  for attr in attrs
    return no unless value.hasOwnProperty attr
  return yes
