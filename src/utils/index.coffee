
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
hasKeys = require "hasKeys"

{isArray} = Array

typeNames =
  boolean: "BOOL"
  number: "NUMBER"
  object: "OBJECT"
  string: "STRING"

utils = exports

# TODO: Add PTYPE<TIME> for dates.
utils.typeOf = (value) ->
  return "NULL" if value is null
  return "ARRAY" if isArray value
  return name if name = typeNames[typeof value]
  throw Error "Unsupported value type"

utils.expect = (value, expectedType) ->
  type = utils.typeOf value
  if type isnt expectedType
    throw Error "Expected type #{expectedType} but found #{type}"

utils.isQuery = (queryTypes, value) ->
  value and inherits value, queryTypes

utils.getField = (value, attr) ->
  return value[attr] if value.hasOwnProperty attr
  throw Error "No attribute `#{attr}` in object"

utils.hasFields = (value, attrs) ->
  for attr in attrs
    return no unless value.hasOwnProperty attr
  return yes

utils.equals = (value1, value2) ->

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

utils.pluck = (input, keys) ->
  pluckWithArray keys, input, {}

# TODO: Support nested objects for `without`.
utils.without = (input, keys) ->
  output = {}
  for key, value of input
    unless ~keys.indexOf key
      output[key] = value
  return output

utils.merge = (output, inputs) ->
  output = utils.clone output

  for input in inputs
    output = merge output, input

  if isArray output
    return utils.resolve output
  return output

# Returns true if the `patch` changed at least one value.
utils.update = (object, patch) ->
  return no if patch is null

  if "OBJECT" isnt utils.typeOf patch
    throw Error "Inserted value must be an OBJECT (got #{utils.typeOf patch})"

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
utils.resolve = (value, ctx) ->

  if utils.isQuery value
    return value._run ctx

  ctx?.type = "DATUM"

  if isArray value
    return resolveArray value

  if isConstructor value, Object
    return resolveObject value

  return value

#
# Helpers
#

inherits = (value, types) ->
  for type in types
    return yes if value instanceof type
  return no

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

    if isConstructor key, String
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

    else if isConstructor value, String
      continue unless isConstructor input[key], Object
      continue unless input[key].hasOwnProperty value
      output[key] = {} unless isConstructor output[key], Object
      output[key][value] = input[key][value]

    else if isArray value
      continue unless isConstructor input[key], Object
      if isConstructor output[key], Object
        pluckWithArray value, input[key], output[key]
      else
        value = pluckWithArray value, input[key], {}
        output[key] = value if hasKeys value

    else if isConstructor value, Object
      continue unless isConstructor input[key], Object
      if isConstructor output[key], Object
        pluckWithObject value, input[key], output[key]
      else
        value = pluckWithObject value, input[key], {}
        output[key] = value if hasKeys value

    else throw TypeError "Invalid path argument"

  return output

# NOTE: Nested queries must be resolved before calling this function.
merge = (output, input) ->

  # Non-objects overwrite the output.
  return input unless isConstructor input, Object

  # Nothing to merge into.
  return input unless isConstructor output, Object

  for key, value of input
    if isConstructor value, Object
      if isConstructor output[key], Object
      then merge output[key], value
      else output[key] = value
    else output[key] = value

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

    if isArray value
      clone[key] = resolveArray value

    else if isConstructor value, Object
      clone[key] = resolveObject value

    else if utils.isQuery value
      clone[key] = value._run()

    else clone[key] = value

  return clone
