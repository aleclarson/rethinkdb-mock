
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"

{isArray} = Array

utils = exports

utils.isQuery = (queryTypes, value) ->
  return no unless value
  return yes if ~queryTypes.indexOf value.constructor
  return no

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

utils.equals = (value1, value2) ->
  value2 = utils.resolve value2

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

    input = utils.resolve input
    output = merge output, input

  return output unless isArray output
  return output.map (value) ->
    utils.resolve value

# Returns true if the `patch` changed at least one value.
utils.update = (object, patch) ->

  if patch.hasOwnProperty "id"
    if patch.id isnt object.id
      throw Error "Primary key `id` cannot be changed"

  return !!update object, patch

# Replicate an object or array (a simpler alternative to `utils.merge`)
utils.clone = (values) ->

  if values is null
    return null

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

# Resolves any queries found in a value.
# Throws an error for undefined values.
utils.resolve = (value) ->
  if isArray value
    return resolveArray value
  if isConstructor value, Object
    return resolveObject value
  if utils.isQuery value
    return value._run()
  return value

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

# NOTE: Nested queries must be resolved before calling this function.
merge = (output, input) ->

  # Non-objects overwrite the output.
  return input unless isConstructor input, Object

  # Ensure the output is an object before merging.
  output = {} unless isConstructor output, Object

  for key, value of input
    output[key] =
      if isConstructor output[key], Object
      then merge output[key], value
      else value

  return output

# NOTE: Nested queries must be resolved before calling this function.
update = (output, input) ->
  changes = 0
  for key, value of input

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

resolveArray = (values) ->
  clone = []
  for value, index in values

    if value is undefined
      throw Error "Cannot wrap undefined with r.expr()"

    if isArray value
      clone.push resolveArray value

    else if isConstructor value, Object
      clone.push resolveObject value

    else if utils.isQuery value
      clone.push value._run()

    else clone.push value

  return clone

resolveObject = (values) ->
  clone = {}
  for key, value of values

    if value is undefined
      throw Error "Object field '#{key}' may not be undefined"

    if isArray value
      clone[key] = resolveArray value

    else if isConstructor value, Object
      clone[key] = resolveObject value

    else if utils.isQuery value
      clone[key] = value._run()

    else clone[key] = value

  return clone
