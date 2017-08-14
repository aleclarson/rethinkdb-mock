
isConstructor = require "isConstructor"

arity = require "./arity"
types = require "./types"
utils = require "../utils"
seq = require "../utils/seq"

seqRE = /TABLE|SELECTION<ARRAY>/

arity.set
  nth: arity.ONE
  offsetsOf: arity.ONE
  contains: arity.ONE
  orderBy: arity.ONE
  map: arity.ONE
  filter: arity.ONE_TWO
  isEmpty: arity.NONE
  count: arity.NONE
  skip: arity.ONE
  limit: arity.ONE
  slice: arity.ONE_THREE

types.set
  nth: types.SELECTION
  offsetsOf: types.DATUM
  contains: types.DATUM
  orderBy: types.SEQUENCE
  map: types.DATUM
  filter: types.SEQUENCE
  isEmpty: types.DATUM
  count: types.DATUM
  skip: types.SEQUENCE
  limit: types.SEQUENCE
  slice: types.SEQUENCE

actions = exports

actions.nth = (result, index) ->
  utils.expect result, "ARRAY"
  utils.expect index, "NUMBER"

  if index < -1 and seqRE.test @type
    throw Error "Cannot use an index < -1 on a stream"

  return seq.nth result, index

# TODO: Support `offsetsOf` function argument
actions.offsetsOf = (array, value) ->
  utils.expect array, "ARRAY"

  if isConstructor value, Function
    throw Error "Function argument not yet implemented"

  offsets = []
  for value2, index in array
    offsets.push index if utils.equals value2, value
  return offsets

# TODO: Support `contains` function argument
actions.contains = (array, value) ->
  utils.expect array, "ARRAY"

  if isConstructor value, Function
    throw Error "Function argument not yet implemented"

  for value2 in array
    return true if utils.equals value, value2
  return false

# TODO: Support sorting by an array/object value.
# TODO: Support `orderBy` function argument
# TODO: Support an {index: 'id'} argument
actions.orderBy = (array, value) ->
  utils.expect array, "ARRAY"

  if isConstructor value, Object
    {DESC, index} = value

  else if isConstructor value, String
    index = value

  utils.expect index, "STRING"
  sorter =
    if DESC
    then sortDescending index
    else sortAscending index

  return array.slice().sort sorter

# TODO: Test if rows are properly cloned when mapped.
actions.map = (array, iterator) ->
  utils.expect array, "ARRAY"
  return array.map (row) ->
    iterator._eval {row}

actions.filter = (array, filter, options) ->
  utils.expect array, "ARRAY"

  if options isnt undefined
    utils.expect options, "OBJECT"
    # TODO: Support `default` option

  if utils.isQuery filter
    return array.filter (row) ->
      result = filter._eval {row}
      (result isnt false) and (result isnt null)

  matchers = []
  if isConstructor filter, Object

    matchers.push (values) ->
      utils.expect values, "OBJECT"
      return true

    utils.each filter, (expected, key) ->
      matchers.push (values) ->
        utils.equals values[key], expected

  # The native API returns the sequence when
  # the filter is neither an object nor function.
  else return array

  return array.filter (row) ->
    for matcher in matchers
      return false unless matcher row
    return true

actions.isEmpty = (array) ->
  utils.expect array, "ARRAY"
  return array.length is 0

actions.count = (array) ->
  utils.expect array, "ARRAY"
  return array.length

actions.skip = (array, count) ->
  utils.expect array, "ARRAY"
  utils.expect count, "NUMBER"

  if count < 0 and seqRE.test @type
    throw Error "Cannot use a negative left index on a stream"

  return array.slice count

actions.limit = (array, count) ->
  utils.expect array, "ARRAY"
  utils.expect count, "NUMBER"

  if count < 0
    throw Error "LIMIT takes a non-negative argument"

  return array.slice 0, count

actions.slice = (result, args) ->
  type = utils.typeOf result

  if type is "ARRAY"
    return seq.slice result, args

  if type is "BINARY"
    throw Error "`slice` does not support BINARY values (yet)"

  if type is "STRING"
    throw Error "`slice` does not support STRING values (yet)"

  throw Error "Expected ARRAY, BINARY, or STRING, but found #{type}"

#
# Helpers
#

# Objects with lesser values come first.
# An undefined value is treated as less than any defined value.
# When two values are equal, the first value is treated as lesser.
sortAscending = (index) -> (a, b) ->
  return 1 if b[index] is undefined
  return 1 if a[index] > b[index]
  return -1

# Objects with greater values come first.
# An undefined value is treated as less than any defined value.
# When two values are equal, the first value is treated as greater.
sortDescending = (index) -> (a, b) ->
  return -1 if b[index] is undefined
  return -1 if a[index] >= b[index]
  return 1
