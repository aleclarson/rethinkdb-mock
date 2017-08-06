
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Query = require "./Query"
utils = require "./utils"
uuid = require "./utils/uuid"

parseArgs = Query::_parseArgs
{isArray} = Array

Table = (db, tableId) ->
  self = (key) -> Query(self, "TABLE").bracket key
  self._db = db
  self._type = "TABLE"
  self._tableId = tableId
  return setType self, Table

methods = Table.prototype

methods.do = (callback) ->
  throw Error "Tables must be coerced to arrays before calling `do`"

methods.get = (rowId) ->

  if rowId is undefined
    throw Error "Cannot convert `undefined` with r.expr()"

  self = Table @_db, @_tableId
  self._action = "get"
  self._rowId = rowId
  return Query self, "SELECTION"

methods.getAll = ->
  self = Table @_db, @_tableId
  self._action = "getAll"
  self._args = arguments
  parseArgs.call self
  return Query self, "SEQUENCE"

methods.insert = (rows, options) ->
  self = Table @_db, @_tableId
  self._action = "insert"
  self._args = arguments
  parseArgs.call self
  return Query self, "DATUM"

methods.delete = ->
  self = Table @_db, @_tableId
  self._action = "delete"
  return Query self, "DATUM"

"nth getField offsetsOf orderBy filter fold count limit slice merge pluck without update"
  .split(" ").forEach (key) ->
    methods[key] = ->
      Query(this, "TABLE")._then key, arguments
    return

methods.run = ->
  Promise.resolve()
    .then Query._run.bind null, this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._run = (ctx) ->
  ctx.type = @_type
  ctx.tableId = @_tableId

  unless table = @_db._tables[@_tableId]
    throw Error "Table `#{@_tableId}` does not exist"

  unless @_action
    return table

  switch @_action

    when "get"
      return getRow table, @_rowId, ctx

    when "getAll"
      return getRows table, @_args

    when "insert"
      return insertRows table, @_args[0], @_args[1]

    when "delete"
      return clearTable table

module.exports = Table

#
# Helpers
#

getRow = (table, rowId, ctx) ->

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

getRows = (table, args) ->

  return [] unless args.length

  if isConstructor args[args.length - 1], Object
    key = args.pop().index

  key ?= "id"
  assertType key, String

  args.forEach (arg, index) ->

    if arg is undefined
      throw Error "Argument #{index} to getAll may not be `undefined`"

    if utils.isQuery arg
      args[index] = arg = arg._run()

    if arg is null
      throw Error "Keys cannot be NULL"

    if isConstructor arg, Object
      throw Error (if key is "id" then "Primary" else "Secondary") + " keys must be either a number, string, bool, pseudotype or array"

  table.filter (row) ->
    for arg in args
      if isArray arg
        return yes if utils.equals arg, row[key]
      else if arg is row[key]
        return yes
    return no

# TODO: Support options argument.
insertRows = (table, rows) ->
  rows = utils.resolve rows
  rows = [rows] unless isArray rows

  errors = 0
  generated_keys = []

  for row in rows
    assertType row, Object

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

findRow = (table, rowId) ->

  if rowId is undefined
    throw Error "Argument 1 to get may not be `undefined`"

  if utils.isQuery rowId
    rowId = rowId._run()

  if (rowId is null) or isConstructor(rowId, Object)
    throw Error "Primary keys must be either a number, string, bool, pseudotype or array"

  table.find (row) -> row.id is rowId

clearTable = (table) ->
  deleted = table.length
  table.length = 0
  return {deleted}
