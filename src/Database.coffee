
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"

Table = require "./Table"
Datum = require "./Datum"
utils = require "./utils"

{isArray} = Array

Database = (name) ->
  assertType name, String
  @_name = name
  @_tables = {}
  return this

methods = Database.prototype

methods.table = (tableId) ->
  return Table this, tableId

methods.tableCreate = (tableId) ->
  throw Error "Not implemented"

methods.tableDrop = (tableId) ->
  throw Error "Not implemented"

# TODO: Support `row`
# methods.row = Row()

# TODO: You cannot have a sequence nested in an expression. You must use `coerceTo` first.
methods.expr = (value) ->
  return Datum
    _db: this
    _run: -> utils.resolve value

methods.uuid = require "./utils/uuid"

# TODO: You cannot have a sequence nested in an object. You must use `coerceTo` first.
methods.object = ->
  args = sliceArray arguments

  if args.length % 2
    throw Error "Expected an even number of arguments"

  return Datum
    _db: this
    _run: -> createObject args

# TODO: Support `args`
# methods.args = (array) -> array

methods.desc = (attr) -> ["desc", attr]

# TODO: Support `do`
# methods.do = ->

# TODO: Support `branch`
# methods.branch = ->

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
