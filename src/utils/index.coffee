
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"

{isArray} = Array

utils = exports

utils.isQuery = (queryTypes, value) ->
  return no unless value
  return yes if ~queryTypes.indexOf value.constructor
  return no

utils.runQueries = (values) ->

  if isArray
    for value, index in values
      if utils.isQuery value
        values[index] = value._run()
      else if isArrayOrObject value
        utils.runQueries value
    return values

  for key, value of values
    if utils.isQuery value
      values[key] = value._run()
    else if isArrayOrObject value
      utils.runQueries value
  return values

# TODO: Prevent indexes less than -1 for streams.
utils.nth = (array, index) ->
  assertType array, Array

  if utils.isQuery index
    index = index._run()

  assertType index, Number

  if index < 0
    index = array.length + index

  if index < 0 or index >= array.length
    throw Error "Index out of bounds"

  return array[index]

utils.access = (value, key) ->

  if utils.isQuery key
    key = key._run()

  if isConstructor key, String
    return utils.getField value, key

  if isConstructor key, Number
    return utils.nth value, key

  throw Error "Expected a Number or String!"

utils.getField = (value, attr) ->

  if utils.isQuery attr
    attr = attr._run()

  assertType attr, String
  unless value.hasOwnProperty attr
    throw Error "No attribute `#{attr}` in object"

  return value[attr]

utils.hasFields = (value, attrs) ->

  for attr, index in attrs

    if attr is undefined
      throw Error "Argument #{index} to hasFields may not be `undefined`"

    unless isConstructor attr, String
      throw Error "Invalid path argument"

    return no unless value.hasOwnProperty attr
  return yes

# TODO: Support sub-queries nested in an array or object.
utils.equals = (value1, value2) ->

  if utils.isQuery value2
    value2 = value2._run()

  else if isArrayOrObject value2
    utils.runQueries value2

  if isArray value1
    return no unless isArray value2
    return arrayEquals value1, value2

  if isConstructor value1, Object
    return no unless isConstructor value2, Object
    return objectEquals value1, value2

  return value1 is value2

utils.flatten = (input, output = []) ->
  assertType input, Array
  assertType output, Array
  for value in input
    if isArray value
    then utils.flatten value, output
    else output.push value
  return output

# TODO: Support sub-queries as keys.
utils.pluck = (input, keys) ->
  assertType input, Object
  assertType keys, Array
  return pluckWithArray keys, input, {}

# TODO: Support sub-queries as keys.
# TODO: Support nested arrays/objects for `without`.
utils.without = (input, keys) ->
  assertType input, Object
  assertType keys, Array
  keys = utils.flatten keys
  output = {}
  for key, value of input
    unless ~keys.indexOf key
      output[key] = value
  return output

utils.merge = (output, inputs) ->
  assertType output, Object
  assertType inputs, Array

  for input in inputs

    if input is undefined
      throw Error "Argument to merge may not be `undefined`"

    if utils.isQuery input
      input = input._run()

    else if isArrayOrObject input
      utils.runQueries input

    output = merge output, input

  return output unless isArray output
  return output.map (value) ->
    return value._run() if utils.isQuery value
    return value unless isArrayOrObject value
    return utils.runQueries value

# Returns true if the `patch` changed at least one value.
utils.update = (object, patch) ->

  if patch.hasOwnProperty "id"
    if patch.id isnt object.id
      throw Error "Primary key `id` cannot be changed"

  return !!update object, patch

# Replicate an object or array (a simpler alternative to `utils.merge`)
utils.clone = (values) ->

  if isArray values
    return values.map (value) ->
      if isArrayOrObject value
      then utils.clone value
      else value

  clone = {}
  for key, value of values
    clone[key] =
      if isArrayOrObject value
      then utils.clone value
      else value

  return clone

#
# Helpers
#

isArrayOrObject = (value) ->
  isArray(value) or isConstructor(value, Object)

arrayEquals = (array1, array2) ->
  return no if array1.length isnt array2.length
  for value1, index in array1
    return no unless utils.equals value1, array2[index]
  return yes

objectEquals = (object1, object2) ->
  keys = Object.keys object1
  for key in Object.keys object2
    return no unless ~keys.indexOf key
  for key in keys
    return no unless utils.equals object1[key], object2[key]
  return yes

pluckWithArray = (array, input, output) ->
  array = utils.flatten array
  for key in array

    if typeof key is "string"
      if input.hasOwnProperty key
        output[key] = input[key]

    else if isConstructor key, Object
      pluckWithObject key, input, output

    else throw TypeError "Invalid path argument"

  return output

pluckWithObject = (object, input, output) ->
  for key, value of object

    if value is true
      if input.hasOwnProperty key
        output[key] = input[key]

    else if typeof value is "string"
      if isConstructor input[key], Object
        output[key] = {}
        output[key][value] = input[key][value]

    else if isArray value
      if isConstructor input[key], Object
        output[key] = pluckWithArray value, input[key], output

    else if isConstructor value, Object
      if isConstructor input[key], Object
        output[key] = pluckWithObject value, input[key], {}

    else throw TypeError "Invalid path argument"

  return output

merge = (output, input) ->

  # Non-objects overwrite the output.
  return input unless isConstructor input, Object

  # Ensure the output is an object before merging.
  output = {} unless isConstructor output, Object

  for key, value of input

    if value is undefined
      throw Error "Object field '#{key}' may not be undefined"

    if utils.isQuery value
      value = value._run()

    else if isArrayOrObject value
      utils.runQueries value

    output[key] =
      if isConstructor output[key], Object
      then merge output[key], value
      else value

  return output

update = (output, input) ->
  changes = 0
  for key, value of input

    if value is undefined
      throw Error "Object field '#{key}' may not be undefined"

    if utils.isQuery value
      value = value._run()

    else if isArrayOrObject value
      utils.runQueries value

    if isConstructor value, Object

      unless isConstructor output[key], Object
        changes += 1
        output[key] = utils.clone value
        continue

      changes += update output[key], value

    else if isArray value

      if isArray output[key]
        continue if arrayEquals value, output[key]

      changes += 1
      output[key] = utils.clone value

    else if value isnt output[key]
      changes += 1
      output[key] = value

  return changes
