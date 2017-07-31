
assertType = require "assertType"

Table = require "./Table"

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

# TODO: Support `expr`
# methods.expr = ->

methods.uuid = require "./utils/uuid"

# TODO: Support `object`
# methods.object = (key, value) ->
#   object = {}
#   object[key] = value
#   return object

# TODO: Support `args`
# methods.args = (array) -> array

methods.desc = (attr) -> ["desc", attr]

# TODO: Support `do`
# methods.do = ->

# TODO: Support `branch`
# methods.branch = ->

module.exports = Database
