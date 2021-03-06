isPlainObj = require 'is-plain-object'

utils = require '.'

{isArray} = Array

seq = exports

seq.nth = (array, index) ->

  if index < 0
    index = array.length + index

  if index < 0 or index >= array.length
    throw RangeError 'Index out of bounds'

  return array[index]

seq.getField = (array, attr) ->
  results = []

  for value in array
    utils.expect value, 'OBJECT'
    if value.hasOwnProperty attr
      results.push value[attr]

  return results

seq.hasFields = (array, attrs) ->
  results = []

  for value in array
    utils.expect value, 'OBJECT'
    if utils.hasFields value, attrs
      results.push value

  return results

# TODO: Throw error for negative indexes on a 'stream'.
seq.slice = (array, args) ->

  options =
    if isPlainObj args[args.length - 1]
    then args.pop()
    else {}

  [startIndex, endIndex] = args
  endIndex ?= array.length

  utils.expect startIndex, 'NUMBER'
  utils.expect endIndex, 'NUMBER'

  if options.leftBound == 'open'
    startIndex += 1

  if options.rightBound == 'closed'
    endIndex += 1

  return array.slice startIndex, endIndex

seq.pluck = (rows, args) ->
  rows.map (row) ->
    utils.pluck row, args

seq.without = (rows, args) ->
  rows.map (row) ->
    utils.without row, args
