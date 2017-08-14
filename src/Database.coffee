
assertType = require "assertType"
sliceArray = require "sliceArray"
setProto = require "setProto"

Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

{isArray} = Array

define = Object.defineProperty
tableRE = /^[A-Z0-9_]+$/i

Database = (name) ->
  assertType name, String

  r = (value) -> r.expr value
  r._name = name

  define r, "_tables",
    value: {}
    writable: true

  return setProto r, Database.prototype

methods = {}

methods.init = (tables) ->
  assertType tables, Object
  for tableId, table of tables
    unless tableRE.test tableId
      throw Error "Table name `#{tableId}` invalid (Use A-Za-z0-9_ only)"

    assertType table, Array
    @_tables[tableId] = table
  return

methods.load = ->
  filePath = require("path").resolve.apply null, arguments
  json = require("fs").readFileSync filePath, "utf8"
  @_tables = JSON.parse json
  return

methods.table = (tableId) ->
  if tableId is undefined
    throw Error "Cannot convert `undefined` with r.expr()"
  return Table this, tableId

# TODO: Support `options` argument
methods.tableCreate = (tableId) ->
  assertType tableId, String
  unless tableRE.test tableId
    throw Error "Table name `#{tableId}` invalid (Use A-Za-z0-9_ only)"

  if @_tables.hasOwnProperty tableId
    throw Error "Table `#{@_name + "." + tableId}` already exists"

  @_tables[tableId] = []
  return Query._expr {tables_created: 1}

methods.tableDrop = (tableId) ->
  assertType tableId, String
  unless tableRE.test tableId
    throw Error "Table name `#{tableId}` invalid (Use A-Za-z0-9_ only)"

  if delete @_tables[tableId]
    return Query._expr {tables_dropped: 1}

  throw Error "Table `#{@_name + "." + tableId}` does not exist"

methods.uuid = require "./utils/uuid"

methods.typeOf = (value) ->
  if arguments.length isnt 1
    throw Error "`typeOf` takes 1 argument, #{arguments.length} provided"
  return Query._expr(value).typeOf()

methods.branch = (cond) ->
  args = sliceArray arguments, 1
  if args.length < 2
    throw Error "`branch` takes at least 3 arguments, #{args.length + 1} provided"
  return Query._branch Query._expr(cond), args

methods.do = (arg) ->
  unless arguments.length
    throw Error "`do` takes at least 1 argument, 0 provided"
  return Query._do Query._expr(arg), sliceArray arguments, 1

# TODO: You cannot have a sequence nested in an expression. You must use `coerceTo` first.
methods.expr = Query._expr

methods.row = Query._row

methods.args = (args) ->

  # TODO: Support passing `r([])` to `r.args`
  if utils.isQuery args
    throw Error "The first argument of `r.args` cannot be a query (yet)"

  utils.expect args, "ARRAY"
  args = args.map (arg) ->
    if utils.isQuery(arg) and arg._lazy
      throw Error "Implicit variable `r.row` cannot be used inside `r.args`"
    return Query._expr arg

  query = Query null, "ARGS"
  query._eval = (ctx) ->
    ctx.type = "DATUM"

    values = []
    args.forEach (arg) ->

      if arg._type is "ARGS"
        values = values.concat arg._run()
        return

      values.push arg._run()
      return

    return values
  return query

# TODO: You cannot have a sequence nested in an object. You must use `coerceTo` first.
methods.object = ->
  args = sliceArray arguments

  if args.length % 2
    throw Error "Expected an even number of arguments"

  args.forEach (arg, index) ->
    if arg is undefined
      throw Error "Argument #{index} to object may not be `undefined`"

  query = Query null, "DATUM"
  query._eval = (ctx) ->
    result = {}

    index = 0
    while index < args.length
      key = utils.resolve args[index]
      utils.expect key, "STRING"
      result[key] = utils.resolve args[index + 1]
      index += 2

    ctx.type = @_type
    return result
  return query

methods.asc = (index) -> {ASC: true, index}
methods.desc = (index) -> {DESC: true, index}

utils.each methods, (value, key) ->
  define Database.prototype, key, {value}

module.exports = Database
