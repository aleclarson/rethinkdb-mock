# TODO: Allow initializing the database with a JSON file.

assertType = require "assertType"

Database = require "./Database"
Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

# Bind the possible query types.
utils.isQuery = utils.isQuery.bind null, [Query, Table]

cache = Object.create null

rethinkdb = (options = {}) ->
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

rethinkdb.isQuery = utils.isQuery
rethinkdb.runQuery = Query._run

module.exports = rethinkdb
