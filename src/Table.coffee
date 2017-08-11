
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setProto = require "setProto"

Query = require "./Query"
utils = require "./utils"
uuid = require "./utils/uuid"

{isArray} = Array

parseArgs = Query::_parseArgs
runQuery = Query::_run
define = Object.defineProperty

Table = (db, tableId) ->
  query = (key) -> query.bracket key
  query._db = db
  query._type = "TABLE"
  query._tableId = tableId
  return setProto query, Table.prototype

methods = {}

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

"nth bracket getField offsetsOf contains orderBy filter fold count limit slice merge pluck without update"
  .split(" ").forEach (key) ->
    methods[key] = ->
      Query(this, "TABLE")._then key, arguments
    return

methods.run = ->
  Promise.resolve()
    .then runQuery.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._eval = (ctx) ->
  ctx.type = @_type
  ctx.tableId = @_tableId

  unless table = @_db._tables[@_tableId]
    throw Error "Table `#{@_tableId}` does not exist"

  unless @_action
    return table

  args = utils.resolve @_args
  switch @_action

    when "get"
      return getRow table, @_rowId, ctx

    when "getAll"
      return getRows table, args

    when "insert"
      return insertRows table, args[0], args[1]

    when "delete"
      return clearTable table

methods._run = runQuery

Object.keys(methods).forEach (key) ->
  define Table.prototype, key,
    value: methods[key]
    writable: yes

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
  utils.expect key, "STRING"

  args.forEach (arg, index) ->

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

# TODO: Support `insert` options argument.
insertRows = (table, rows) ->
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
