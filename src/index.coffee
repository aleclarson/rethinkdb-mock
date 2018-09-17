isPlainObj = require 'is-plain-object'
TypeError = require 'type-error'

Database = require './Database'
Table = require './Table'
Query = require './Query'
utils = require './utils'

# Bind the possible query types.
utils.isQuery = utils.isQuery.bind null, [Query, Table]

cache = Object.create null

rethinkdb = (options = {}) ->
  if !isPlainObj options
    throw TypeError Object, options

  name = options.name or 'test'
  return db if db = cache[name]

  db = Database name
  cache[name] = db
  return db

module.exports = rethinkdb
