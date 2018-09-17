isPlainObj = require 'is-plain-object'
TypeError = require 'type-error'
sliceArray = require 'sliceArray'
hasKeys = require 'hasKeys'

{isArray} = Array

typeNames =
  boolean: 'BOOL'
  function: 'FUNCTION'
  number: 'NUMBER'
  object: 'OBJECT'
  string: 'STRING'

utils = exports

# TODO: Add PTYPE<TIME> for dates.
utils.typeOf = (value) ->
  return 'NULL' if value == null
  return 'ARRAY' if isArray value
  return name if name = typeNames[typeof value]
  throw Error 'Unsupported value type'

utils.expect = (value, expectedType) ->
  type = utils.typeOf value
  if type != expectedType
    throw Error "Expected type #{expectedType} but found #{type}"

utils.isQuery = (queryTypes, value) ->
  value and inherits value, queryTypes

utils.getField = (value, attr) ->
  return value[attr] if value.hasOwnProperty attr
  throw Error "No attribute `#{attr}` in object"

utils.hasFields = (value, attrs) ->
  for attr in attrs
    return false unless value.hasOwnProperty attr
  return true

utils.equals = (value1, value2) ->

  if isArray value1
    return false unless isArray value2
    return arrayEquals value1, value2

  if isPlainObj value1
    return false unless isPlainObj value2
    return objectEquals value1, value2

  return value1 == value2

utils.flatten = (input, output = []) ->
  if !Array.isArray input
    throw TypeError Array, input
  if !Array.isArray output
    throw TypeError Array, output
  for value in input
    if isArray value
    then utils.flatten value, output
    else output.push value
  return output

utils.pluck = (input, keys) ->
  pluckWithArray keys, input, {}

# TODO: Support nested objects for `without`.
utils.without = (input, keys) ->
  output = {}
  for key, value of input
    unless ~keys.indexOf key
      output[key] = value
  return output

# Returns true if the `patch` changed at least one value.
utils.update = (object, patch) ->
  return false if patch == null

  if 'OBJECT' != utils.typeOf patch
    throw Error "Inserted value must be an OBJECT (got #{utils.typeOf patch})"

  if patch.hasOwnProperty 'id'
    if patch.id != object.id
      throw Error 'Primary key `id` cannot be changed'

  return !!update object, patch

# Replicate an object or array (a simpler alternative to `utils.merge`)
utils.clone = (value) ->
  return null if value == null
  return utils.cloneArray value if isArray value
  return utils.cloneObject value if isPlainObj value
  return value

utils.cloneArray = (values) ->
  clone = new Array values.length
  for value, index in values
    clone[index] = utils.clone value
  return clone

utils.cloneObject = (values) ->
  clone = {}
  for key, value of values
    clone[key] = utils.clone value
  return clone

utils.each = (values, iterator) ->
  for key, value of values
    iterator value, key
  return

# Resolve all queries, cloning any selections.
# If a context is passed, its `type` is mutated.
utils.resolve = (value, ctx) ->

  if utils.isQuery value
    return value._run ctx

  ctx?.type = 'DATUM'

  if isArray value
    return resolveArray value, ctx

  if isPlainObj value
    return resolveObject value, ctx

  return value

#
# Helpers
#

inherits = (value, types) ->
  for type in types
    return true if value instanceof type
  return false

arrayEquals = (array1, array2) ->
  return false if array1.length != array2.length
  for value1, index in array1
    return false unless utils.equals value1, array2[index]
  return true

objectEquals = (object1, object2) ->
  keys = Object.keys object1
  for key in Object.keys object2
    return false unless ~keys.indexOf key
  for key in keys
    return false unless utils.equals object1[key], object2[key]
  return true

pluckWithArray = (array, input, output) ->
  array = utils.flatten array
  for key in array

    if typeof key == 'string'
      if input.hasOwnProperty key
        output[key] = input[key]

    else if isPlainObj key
      pluckWithObject key, input, output

    else throw TypeError 'Invalid path argument'

  return output

pluckWithObject = (object, input, output) ->
  for key, value of object

    if value == true
      if input.hasOwnProperty key
        output[key] = input[key]

    else if typeof value == 'string'
      continue unless isPlainObj input[key]
      continue unless input[key].hasOwnProperty value
      output[key] = {} unless isPlainObj output[key]
      output[key][value] = input[key][value]

    else if isArray value
      continue unless isPlainObj input[key]
      if isPlainObj output[key]
        pluckWithArray value, input[key], output[key]
      else
        value = pluckWithArray value, input[key], {}
        output[key] = value if hasKeys value

    else if isPlainObj value
      continue unless isPlainObj input[key]
      if isPlainObj output[key]
        pluckWithObject value, input[key], output[key]
      else
        value = pluckWithObject value, input[key], {}
        output[key] = value if hasKeys value

    else throw TypeError 'Invalid path argument'

  return output

# NOTE: Nested queries must be resolved before calling this function.
update = (output, input) ->
  changes = 0
  for key, value of input

    if isPlainObj value

      unless isPlainObj output[key]
        changes += 1
        output[key] = utils.cloneObject value
        continue

      changes += update output[key], value

    else if isArray value

      if isArray output[key]
        continue if arrayEquals value, output[key]

      changes += 1
      output[key] = utils.cloneArray value

    else if value != output[key]
      changes += 1
      output[key] = value

  return changes

resolve = (value, ctx) ->

  if isArray value
    return resolveArray value, ctx

  if isPlainObj value
    return resolveObject value, ctx

  if utils.isQuery value
    ctx = Object.assign {}, ctx
    return value._run ctx

  return value

resolveArray = (values, ctx) ->
  values.map (value) ->
    resolve value, ctx

resolveObject = (values, ctx) ->
  clone = {}
  for key, value of values
    clone[key] = resolve value, ctx
  return clone
