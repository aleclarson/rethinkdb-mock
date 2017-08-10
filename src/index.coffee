
assertType = require "assertType"
setProto = require "setProto"

Database = require "./Database"
Table = require "./Table"
Query = require "./Query"
utils = require "./utils"

# Avoid circular dependencies by inheriting from `Query` here.
setProto require("./Result").prototype, Query.prototype

# Bind the possible query types.
utils.isQuery = utils.isQuery.bind null, [Query, Table]

cache = Object.create null

rethinkdb = (options = {}) ->
  assertType options, Object

  name = options.name or "test"
  return db if db = cache[name]

  db = Database name
  cache[name] = db
  return db

module.exports = rethinkdb
