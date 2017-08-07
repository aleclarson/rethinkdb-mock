# TODO: Support time math with other times or numbers.
# TODO: Comparison of objects/arrays with `gt`, `lt`, `ge`, `le`

utils = require "./utils"
seq = require "./utils/seq"

{isArray} = Array

actions = exports

actions.eq = (result, args) ->
  equals result, args

actions.ne = (result, args) ->
  !equals result, args

actions.gt = (result, args) ->
  prev = result
  for arg in args
    return no if prev <= arg
    prev = arg
  return yes

actions.lt = (result, args) ->
  prev = result
  for arg in args
    return no if prev >= arg
    prev = arg
  return yes

actions.ge = (result, args) ->
  prev = result
  for arg in args
    return no if prev < arg
    prev = arg
  return yes

actions.le = (result, args) ->
  prev = result
  for arg in args
    return no if prev > arg
    prev = arg
  return yes

actions.or = (result, args) ->
  return result unless isFalse result
  for arg in args
    return arg unless isFalse arg
  return args.pop()

actions.and = (result, args) ->
  return result if isFalse result
  for arg in args
    return arg if isFalse arg
  return args.pop()

# TODO: Support dates and sequences.
actions.add = (result, args) ->
  type = utils.typeOf result
  unless /ARRAY|NUMBER|STRING/.test type
    throw Error "Expected type ARRAY, NUMBER, or STRING but found #{type}"

  total = result
  for arg in args
    utils.expect arg, type
    if type is "ARRAY"
    then total = total.concat arg
    else total += arg

  return total

actions.sub = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total -= arg
  return null

actions.mul = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total *= arg
  return null

actions.div = (result, args) ->
  utils.expect result, "NUMBER"
  total = result
  for arg in args
    utils.expect arg, "NUMBER"
    total /= arg
  return null

actions.nth = seq.nth

actions.bracket = (result, key) ->

  if utils.isQuery key
    key = key._run()

  keyType = utils.typeOf key
  if keyType is "NUMBER"
    return seq.nth result, key

  if keyType isnt "STRING"
    throw Error "Expected NUMBER or STRING as second argument to `bracket` but found #{keyType}"

  resultType = utils.typeOf result
  if resultType is "ARRAY"
    return seq.bracket result, key

  if resultType is "OBJECT"
    return utils.getField result, key

  throw Error "Expected ARRAY or OBJECT as first argument to `bracket` but found #{resultType}"

actions.getField = (result, attr) ->
  resultType = utils.typeOf result

  if resultType is "ARRAY"
    return seq.getField result, attr

  if resultType is "OBJECT"
    return utils.getField result, attr

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

actions.hasFields = (result, attrs) ->
  resultType = utils.typeOf result

  if resultType is "ARRAY"
    return seq.hasFields result, attrs

  if resultType is "OBJECT"
    return utils.hasFields result, attrs

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

# TODO: Support `offsetsOf` function argument
actions.offsetsOf = (array, value) ->
  utils.expectArray array

  if value is undefined
    throw Error "Argument 1 to offsetsOf may not be `undefined`"

  if utils.isQuery value
    value = value._run()

  if isConstructor value, Function
    throw Error "Function argument not yet implemented"

  offsets = []
  for value2, index in array
    offsets.push index if utils.equals value2, value
  return offsets

# TODO: Support sorting by an array/object value.
# TODO: Support `orderBy` function argument
actions.orderBy = (array, value) ->
  utils.expectArray array

  if value is undefined
    throw Error "Argument 1 to orderBy may not be `undefined`"

  if utils.isQuery value
    value = value._run()

  if isConstructor value, Object
    {DESC, index} = value

  else if isConstructor value, String
    index = value

  sorter =
    if DESC
    then sortDescending index
    else sortAscending index

  assertType index, String
  return array.slice().sort sorter

actions.filter = (array, filter, options) ->
  utils.expectArray array
  return seq.filter array, filter, options

actions.fold = ->
  throw Error "Not implemented"

actions.count = (array) ->
  utils.expectArray array
  return array.length

actions.limit = (result, count) ->
  utils.expectArray result

  if utils.isQuery count
    count = count._run()

  utils.expect count, "NUMBER"
  if count < 0
    throw Error "Cannot call `limit` with a negative number"

  return result.slice 0, count

actions.slice = (result, args) ->

  resultType = utils.typeOf result
  if resultType is "ARRAY"
    return seq.slice result, args

  if resultType is "BINARY"
    throw Error "`slice` does not support BINARY values (yet)"

  if resultType is "STRING"
    throw Error "`slice` does not support STRING values (yet)"

  throw Error "Expected ARRAY, BINARY, or STRING, but found #{resultType}"

actions.merge = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "ARRAY"
    return seq.merge result, args

  if resultType is "OBJECT"
    return utils.merge result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

actions.pluck = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "ARRAY"
    return seq.pluck result, args

  if resultType is "OBJECT"
    return utils.pluck result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

actions.without = (result, args) ->
  resultType = utils.typeOf result

  if resultType is "ARRAY"
    return seq.without result, args

  if resultType is "OBJECT"
    return utils.without result, args

  throw Error "Expected ARRAY or OBJECT but found #{resultType}"

actions.update = (result, patch) ->
  if isArray result
    return updateRows.call this, result, patch
  return updateRow.call this, result, patch

actions.replace = (row, values) ->

  if @type isnt "SELECTION"
    throw Error "Expected type SELECTION but found #{@type}"

  table = @db._tables[@tableId]
  if values is null

    if row is null
      return {deleted: 0, skipped: 1}

    table.splice @rowIndex, 1
    return {deleted: 1, skipped: 0}

  if "OBJECT" isnt utils.typeOf values
    throw Error "Inserted value must be an OBJECT (got #{utils.typeOf values})"

  unless values.hasOwnProperty "id"
    throw Error "Inserted object must have primary key `id`"

  if values.id isnt @rowId
    throw Error "Primary key `id` cannot be changed"

  if row is null
    table.push utils.clone values
    return {inserted: 1}

  if utils.equals row, values
    return {replaced: 0, unchanged: 1}

  table[@rowIndex] = utils.clone values
  return {replaced: 1, unchanged: 0}

actions.delete = (result) ->
  if isArray result
    return deleteRows.call this, result
  return deleteRow.call this, result

#
# Helpers
#

equals = (result, args) ->
  for arg in args
    return no unless utils.equals result, arg
  return yes

isFalse = (value) ->
  (value is null) or (value is false)

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

updateRows = (rows, patch) ->

  if @type isnt "SEQUENCE"
    throw Error "Expected type SEQUENCE but found #{@type}"

  unless rows.length
    return {replaced: 0, unchanged: 0}

  if patch is null
    return {replaced: 0, unchanged: rows.length}

  utils.expect patch, "OBJECT"

  replaced = 0
  for row in rows
    if utils.update row, patch
      replaced += 1

  return {replaced, unchanged: rows.length - replaced}

updateRow = (row, patch) ->

  if @type isnt "SELECTION"
    throw Error "Expected type SELECTION but found #{@type}"

  if row is null
    return {replaced: 0, skipped: 1}

  if utils.update row, patch
    return {replaced: 1, unchanged: 0}

  return {replaced: 0, unchanged: 1}

deleteRows = (rows) ->

  if @type isnt "SEQUENCE"
    throw Error "Expected type SEQUENCE but found #{@type}"

  unless rows.length
    return {deleted: 0}

  deleted = 0
  @db._tables[@tableId] =
    @db._tables[@tableId].filter (row) ->
      if ~rows.indexOf row
        deleted += 1
        return no
      return yes

  return {deleted}

deleteRow = (row) ->

  if row is null
    return {deleted: 0, skipped: 1}

  if @type isnt "SELECTION"
    throw Error "Expected type SELECTION but found #{@type}"

  @db._tables[@tableId].splice @rowIndex, 1
  return {deleted: 1, skipped: 0}