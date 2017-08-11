
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
    writable: true

module.exports = Table
