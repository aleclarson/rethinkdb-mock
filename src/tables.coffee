
assertType = require "assertType"

cache = null

exports.init = (tables) ->
  assertType tables, Object
  cache = tables
  return

exports.get = (tableId) ->
  assertType tableId, String
  return cache[tableId]

exports.set = (tableId, table) ->
  assertType tableId, String
  assertType table, Array
  cache[tableId] = table
  return

exports.drop = (tableId) ->
  assertType tableId, String
  delete cache[tableId]
  return
