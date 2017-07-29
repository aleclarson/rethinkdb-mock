
isConstructor = require "isConstructor"
assertType = require "assertType"

utils = require "."

{isArray} = Array

seq = exports

seq.access = (array, value) ->

  if utils.isQuery value
    value = value._run()

  if isConstructor value, Number
  then seq.nth array, value
  else seq.getField array, value

seq.nth = (array, index) ->

  if utils.isQuery index
    index = index._run()

  assertType index, Number
  if index is -1
    return array[array.length - 1]

  if index < 0
    throw Error "Cannot use an index < -1"

  return array[index]

seq.getField = (array, attr) ->

  if utils.isQuery attr
    attr = attr._run()

  assertType attr, String
  return array.map (value) ->
    assertType value, Object
    return value[attr]

seq.filter = (array, args) ->
  utils.runQueries args

  # TODO: Support `default` option
  # if isConstructor args[1], Object

  matchers = []
  if isConstructor args[0], Object

    matchers.push (values) ->
      assertType values, Object
      return yes

    # TODO: Support nested objects.
    Object.keys(args[0]).forEach (key) ->
      value = args[0][key]

      if utils.isQuery value
        value = value._run()

      matchers.push (values) ->
        return values[key] is value

  # TODO: Support function argument
  else if isConstructor args[0], Function
    # NOTE: May want to call function before this query runs.
    throw Error "Filter functions are not implemented"

  else throw TypeError "Expected an Object or Function!"

  return array.filter (row) ->
    for matcher in matchers
      return no unless matcher row
    return yes

# TODO: Support sorting by an array/object value.
seq.sort = (array, args) ->
  utils.runQueries args

  if isArray args[0]
    sort = args[0][0]
    key = args[0][1]

  else if isConstructor args[0], String
    sort = "asc"
    key = args[0]

  if sort is "asc"
    sorter = sortAscending

  else if sort is "desc"
    sorter = sortDescending

  else throw Error "Invalid sort algorithm: '#{sort}'"

  assertType key, String
  return array.slice().sort sorter

seq.limit = (array, n) ->

  if utils.isQuery n
    n = n._run()

  assertType n, Number
  if n < 0
    throw Error "Cannot call `limit` with a negative number"

  return array.slice 0, n

# TODO: Throw error for negative indexes on a "stream".
seq.slice = (array, args) ->
  utils.runQueries args

  options =
    if isConstructor args[args.length - 1], Object
    then args.pop()
    else {}

  [startIndex, endIndex] = args
  startIndex ?= 0
  endIndex ?= array.length

  if options.leftBound is "open"
    startIndex += 1

  if options.rightBound is "closed"
    endIndex += 1

  return array.slice startIndex, endIndex

#
# Helpers
#

# Objects with lesser values come first.
# An undefined value is treated as less than any defined value.
# When two values are equal, the first value is treated as lesser.
sortAscending = (key) -> (a, b) ->
  return 1 if b[key] is undefined
  return 1 if a[key] > b[key]
  return -1

# Objects with greater values come first.
# An undefined value is treated as less than any defined value.
# When two values are equal, the first value is treated as greater.
sortDescending = (key) -> (a, b) ->
  return -1 if b[key] is undefined
  return -1 if a[key] >= b[key]
  return 1
