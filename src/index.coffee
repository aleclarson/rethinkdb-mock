
assertType = require "assertType"

Database = require "./Database"
utils = require "./utils"

module.exports = (options = {}) ->
  assertType options, Object

  db = new Database options.name or "test"
  db.init = (tables) ->
    assertType tables, Object
    for tableId, table of tables
      db._tables[tableId] = table
    return

  return db

#
# Helpers
#

queryTypes = [
  require "./Selection"
  require "./Sequence"
  require "./Datum"
  require "./Table"
]

utils.isQuery = (value) ->
  return no unless value
  return yes if ~queryTypes.indexOf value.constructor
  return no

utils.runQueries = (args) ->
  for arg, index in args
    args[index] = arg._run() if utils.isQuery arg
  return
