
assertType = require "assertType"
isType = require "isType"

Selection = require "./Selection"
Table = require "./Table"

db = exports

db.table = (tableId) -> Table tableId

db.row = Selection()

db.uuid = require "./uuid"

db.object = (key, value) ->
  object = {}
  object[key] = value
  return object

db.args = (array) -> array

db.desc = (attr) -> ["desc", attr]

db.do = ->
  throw Error "Not implemented"

db.branch = ->
  throw Error "Not implemented"

module.exports = (options = {}) ->
  assertType options, Object

  if options.tables
    require("./tables").init options.tables

  return db
