
isConstructor = require "isConstructor"
assertType = require "assertType"

{isArray} = Array

utils = exports

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
  assertType input, Object
  assertType keys, Array
  return pluckWithArray keys, input, {}

# TODO: Support nested arrays/objects for `without`.
utils.without = (input, keys) ->
  assertType input, Object
  assertType keys, Array
  output = {}
  for key, value of input
    unless ~keys.indexOf key
      output[key] = value
  return output

#
# Helpers
#

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
