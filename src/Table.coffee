
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setProto = require "setProto"

actions = require "./actions"
Query = require "./Query"
utils = require "./utils"

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

"get getAll insert delete"
.split " "
.forEach (actionId) ->
  maxArgs = actions[actionId].arity[1]
  actionType = actions[actionId].type
  methods[actionId] = ->
    query = Table @_db, @_tableId
    query._actionId = actionId
    if maxArgs > 0
      query._args = arguments
      parseArgs.call query
    return Query query, actionType

"""
nth bracket getField hasFields offsetsOf contains orderBy map filter
count limit slice merge pluck without update replace
"""
.split /\r|\s/
.forEach (actionId) ->
  methods[actionId] = ->
    return Query this, "TABLE"
      ._then actionId, arguments

methods.run = ->
  Promise.resolve()
    .then runQuery.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._eval = (ctx) ->

  unless table = @_db._tables[@_tableId]
    throw Error "Table `#{@_tableId}` does not exist"

  ctx.type = @_type
  ctx.tableId = @_tableId

  unless @_actionId
    return table

  args = @_args
  if utils.isQuery args
    args = args._run()
    utils.assertArity @_actionId, args

  return actions[@_actionId].call ctx, table, args

methods._run = runQuery

utils.each methods, (method, key) ->
  define Table.prototype, key,
    value: method
    writable: true

module.exports = Table
