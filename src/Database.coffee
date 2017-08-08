
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"

Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

{isArray} = Array

define = Object.defineProperty

Database = (name) ->
  assertType name, String
  @_name = name
  define this, "_tables",
    value: {}
    writable: yes
  return this

methods = {}

methods.init = (tables) ->
  assertType tables, Object
  @_tables = tables
  return

methods.table = (tableId) ->
  self = Table this, tableId
  if tableId is undefined
    self._error = Error "Cannot convert `undefined` with r.expr()"
  return self

methods.tableCreate = (tableId) ->
  throw Error "Not implemented"

methods.tableDrop = (tableId) ->
  throw Error "Not implemented"

methods.uuid = require "./utils/uuid"

methods.typeOf = (value) ->
  Query._expr(value).typeOf()

# TODO: You cannot have a sequence nested in an expression. You must use `coerceTo` first.
methods.expr = Query._expr

# TODO: You cannot have a sequence nested in an object. You must use `coerceTo` first.
methods.object = ->
  args = sliceArray arguments

  if args.length % 2
    throw Error "Expected an even number of arguments"

  args.forEach (arg, index) ->
    if arg is undefined
      throw Error "Argument #{index} to object may not be `undefined`"

  self = Query()
  self._type = "DATUM"
  self._eval = (ctx) ->
    result = {}

    index = 0
    while index < args.length
      key = utils.resolve args[index]
      utils.expect key, "STRING"
      result[key] = utils.resolve args[index + 1]
      index += 2

    ctx.type = @_type
    return result
  return self

# TODO: Support `args`
# methods.args = (array) ->

methods.asc = (index) -> {ASC: yes, index}
methods.desc = (index) -> {DESC: yes, index}

# TODO: Support `do`
# methods.do = ->

# TODO: Support `branch`
# methods.branch = ->

# TODO: Support `row`
# methods.row = do ->

Object.keys(methods).forEach (key) ->
  define Database.prototype, key,
    value: methods[key]

module.exports = Database
