# Utilities for table rows

assertType = require "assertType"

utils = require "."

row = exports

row.replace = (db, context, row, values) ->
  {tableId, rowId, rowIndex} = context

  if values is undefined
    throw Error "Argument 1 to replace may not be `undefined`"

  values = utils.resolve values

  table = db._tables[tableId]
  if values is null

    if row is null
      return {skipped: 1}

    table.splice rowIndex, 1
    return {deleted: 1}

  if "OBJECT" isnt utils.typeOf values
    throw Error "Inserted value must be an OBJECT (got #{utils.typeOf values})"

  unless values.hasOwnProperty "id"
    throw Error "Inserted object must have primary key `id`"

  if values.id isnt rowId
    throw Error "Primary key `id` cannot be changed"

  if row is null
    table.push utils.clone values
    return {inserted: 1}

  if utils.equals row, values
    return {unchanged: 1}

  table[rowIndex] = utils.clone values
  return {replaced: 1}

row.update = (row, values) ->

  if values is undefined
    throw Error "Argument 1 to update may not be `undefined`"

  unless row
    return {skipped: 1}

  if utils.isQuery values
    values = values._run()
    if values isnt null
      assertType values, Object

  else if values isnt null
    assertType values, Object
    values = utils.resolve values

  if values and utils.update row, values
    return {replaced: 1}

  return {unchanged: 1}

row.delete = (db, tableId, row) ->
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
