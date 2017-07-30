
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

  results = []

  assertType attr, String
  array.forEach (value) ->
    assertType value, Object
    if value.hasOwnProperty attr
      results.push value[attr]
      return

  return results

# TODO: Support `offsetsOf` function argument
seq.offsetsOf = (array, value) ->

  if utils.isQuery value
    value = value._run()

  if value is undefined
    throw Error "Argument 1 to offsetsOf may not be `undefined`"

  if isConstructor value, Function
    throw Error "Function argument not yet implemented"

  offsets = []
  for value2, index in array
    offsets.push index if utils.equals value2, value
  return offsets

seq.filter = (array, args) ->
  utils.runQueries args

  if args[0] is undefined
    throw Error "Argument 1 to filter may not be `undefined`"

  if args.length > 1
    assertType options = args[1], Object
    # TODO: Support `default` option
    # TODO: Support sub-queries in the `options` object.

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
    throw Error "Filter functions are not implemented yet"

  # The native API returns the sequence when
  # the filter is neither an object nor function.
  else return array.slice()

  return array.filter (row) ->
    for matcher in matchers
      return no unless matcher row
    return yes

# TODO: Support sorting by an array/object value.
# TODO: Support `orderBy` function argument
seq.sort = (array, args) ->
  utils.runQueries args

  if isArray args[0]
    sort = args[0][0]
    key = args[0][1]

  else if isConstructor args[0], String
    sort = "asc"
    key = args[0]

  if sort is "asc"
    sorter = sortAscending key

  else if sort is "desc"
    sorter = sortDescending key

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

  if (args.length < 1) or (args.length > 3)
    throw Error "Expected between 1 and 3 arguments but found #{args.length}"

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
