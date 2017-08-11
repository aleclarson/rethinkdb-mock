
isConstructor = require "isConstructor"

arity = require "./arity"
types = require "./types"
utils = require "../utils"

{isArray} = Array

arity.set
  get: arity.ONE
  getAll: arity.ONE_PLUS
  insert: arity.ONE_TWO
  update: arity.ONE_TWO
  replace: arity.ONE_TWO
  delete: arity.NONE

types.set
  get: "SELECTION"
  getAll: "SEQUENCE"
  insert: types.DATUM
  update: types.DATUM
  replace: types.DATUM
  delete: types.DATUM

actions = exports

actions.get = (table, rowId, ctx) ->

  if rowId is undefined
    throw Error "Argument 1 to get may not be `undefined`"

  if utils.isQuery rowId
    rowId = rowId._run()

  if (rowId is null) or isConstructor(rowId, Object)
    throw Error "Primary keys must be either a number, string, bool, pseudotype or array"

  ctx.rowId = rowId
  ctx.rowIndex = -1

  index = -1
  while ++index < table.length
    if table[index].id is rowId
      ctx.rowIndex = index
      return table[index]

  return null

actions.getAll = (table, args) ->
  return [] unless args.length

  if isConstructor args[args.length - 1], Object
    key = args.pop().index

  key ?= "id"
  utils.expect key, "STRING"

  args.forEach (arg, index) ->

    if arg is null
      throw Error "Keys cannot be NULL"

    if isConstructor arg, Object
      throw Error (if key is "id" then "Primary" else "Secondary") + " keys must be either a number, string, bool, pseudotype or array"

  table.filter (row) ->
    for arg in args
      if isArray arg
        return true if utils.equals arg, row[key]
      else if arg is row[key]
        return true
    return false

# TODO: Support `insert` options argument.
actions.insert = (table, rows) ->
  rows = [rows] unless isArray rows

  errors = 0
  generated_keys = []

  for row in rows
    utils.expect row, "OBJECT"

    # Check for duplicate primary keys.
    if row.hasOwnProperty "id"
      if findRow table, row.id
      then errors += 1
      else table.push row

    # Generate an `id` for rows without one.
    else
      generated_keys.push row.id = uuid()
      table.push row

  res = {errors}

  if errors > 0
    res.first_error = "Duplicate primary key `id`"

  res.inserted = rows.length - errors

  if generated_keys.length
    res.generated_keys = generated_keys

  return res

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

findRow = (table, rowId) ->

  if rowId is undefined
    throw Error "Argument 1 to get may not be `undefined`"

  if utils.isQuery rowId
    rowId = rowId._run()

  if (rowId is null) or isConstructor(rowId, Object)
    throw Error "Primary keys must be either a number, string, bool, pseudotype or array"

  table.find (row) -> row.id is rowId

updateRows = (rows, patch) ->

  if @type is "DATUM"
    throw Error "Expected type SEQUENCE but found DATUM"

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

  if @type is "TABLE"
    deleted = rows.length
    rows.length = 0
    return {deleted}

  if @type isnt "SEQUENCE"
    throw Error "Expected type SEQUENCE but found #{@type}"

  unless rows.length
    return {deleted: 0}

  deleted = 0
  @db._tables[@tableId] =
    @db._tables[@tableId].filter (row) ->
      if ~rows.indexOf row
        deleted += 1
        return false
      return true

  return {deleted}

deleteRow = (row) ->

  if row is null
    return {deleted: 0, skipped: 1}

  if @type isnt "SELECTION"
    throw Error "Expected type SELECTION but found #{@type}"

  @db._tables[@tableId].splice @rowIndex, 1
  return {deleted: 1, skipped: 0}
