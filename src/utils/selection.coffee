
assertType = require "assertType"

utils = require "."

sel = exports

sel.replace = (db, tableId, rowId, values) ->

  if utils.isQuery values
    values = values._run()

  if values is undefined
    throw Error "Argument 1 to replace may not be `undefined`"

  table = db._tables[tableId]
  index = indexOf table, rowId
  if values is null
    table.splice index, 1
    return {deleted: 1}

  assertType values, Object
  unless values.hasOwnProperty "id"
    throw Error "Inserted object must have primary key `id`"

  if values.id isnt rowId
    throw Error "Primary key `id` cannot be changed"

  if utils.equals table[index], values
    return {unchanged: 1}

  table[index] = values
  return {replaced: 1}

sel.update = (row, values) ->

  unless row
    return {skipped: 1}

  if utils.isQuery values
    values = values._run()

  assertType values, Object
  if values.hasOwnProperty "id"
    if values.id isnt row.id
      throw Error "Primary key `id` cannot be changed"

  utils.merge row, values
  return {replaced: 1}

sel.delete = (db, tableId, row) ->
  assertType tableId, String

  unless row
    return {skipped: 1}

  table = db._tables[tableId]
  table.splice table.indexOf(row), 1
  return {deleted: 1}

#
# Helpers
#

indexOf = (table, rowId) ->
  index = -1
  while ++index < table.length
    return index if table[index].id is rowId
  return -1
