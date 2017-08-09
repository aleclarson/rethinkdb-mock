
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

{isArray} = Array

define = Object.defineProperty

Database = (name) ->
  assertType name, String

  self = (value) ->
    self.expr value

  self._name = name
  define self, "_tables",
    value: {}
    writable: yes

  return setType self, Database

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
