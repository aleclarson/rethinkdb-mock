
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"

Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

{isArray} = Array

Database = (name) ->
  assertType name, String
  @_name = name
  @_tables = {}
  return this

methods = Database.prototype

methods.table = (tableId) ->
  self = Table this, tableId
  if tableId is undefined
    self._error = Error "Cannot convert `undefined` with r.expr()"
  return self

methods.tableCreate = (tableId) ->
  throw Error "Not implemented"

methods.tableDrop = (tableId) ->
  throw Error "Not implemented"

# TODO: Support `row`
Object.defineProperty methods, "row",
  enumerable: yes
  get: -> Row this

methods.uuid = require "./utils/uuid"

methods.typeOf = (value) ->
  return Query
    _run: ->
      if value is undefined
        throw Error "Cannot convert `undefined` with r.expr()"
      if utils.isQuery value
        return utils.typeOf value._run()
      return utils.typeOf value

# TODO: You cannot have a sequence nested in an expression. You must use `coerceTo` first.
methods.expr = Query._expr

# TODO: You cannot have a sequence nested in an object. You must use `coerceTo` first.
methods.object = ->
  args = sliceArray arguments

  if args.length % 2
    throw Error "Expected an even number of arguments"

  return Query
    _db: this
    _run: -> createObject args

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

module.exports = Database

#
# Helpers
#

createObject = (args) ->
  object = {}

  index = 0
  while index < args.length

    key = utils.resolve args[index]
    assertType key, String

    if args[index + 1] is undefined
      throw Error "Argument #{index + 1} to object may not be `undefined`"

    object[key] = utils.resolve args[index + 1]
    index += 2

  return object
