# TODO: Allow initializing the database with a JSON file.

assertType = require "assertType"

Database = require "./Database"
utils = require "./utils"

cache = Object.create null

module.exports = (options = {}) ->
  assertType options, Object

  name = options.name or "test"
  return db if db = cache[name]

  db = new Database name
  db.init = (tables) ->
    assertType tables, Object
    @_tables = tables
    return

  cache[name] = db
  return db

# Bind the possible query types.
utils.isQuery = utils.isQuery.bind utils, [
  require "./Selection"
  require "./Sequence"
  require "./Datum"
  require "./Table"
]
