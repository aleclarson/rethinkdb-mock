
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"

Selection = require "./Selection"
Sequence = require "./Sequence"
Datum = require "./Datum"
utils = require "./utils"
uuid = require "./utils/uuid"

{isArray} = Array

i = 1
GET = i++
GET_ALL = i++
INSERT = i++
DELETE = i++

Table = (db, tableId, action) ->
  self = (key) -> Sequence(self)._access key
  self._db = db
  self._tableId = tableId
  self._action = action if action
  return setType self, Table

methods = Table.prototype

methods.do = (callback) ->
  throw Error "Tables must be coerced to arrays before calling `do`"

methods.get = (id) ->
  Selection Table @_db, @_tableId, [GET, id]

methods.getAll = ->
  Sequence Table @_db, @_tableId, [GET_ALL, sliceArray arguments]

methods.insert = (value, options) ->
  Datum Table @_db, @_tableId, [INSERT, value, options]

methods.delete = ->
  Datum Table @_db, @_tableId, [DELETE]

do ->
  keys = "nth getField offsetsOf update filter orderBy limit slice pluck without fold".split " "
  keys.forEach (key) ->
    methods[key] = ->
      self = Sequence this
      self[key].apply self, arguments

methods.run = ->
  Promise.resolve().then =>
    return @_run() if @_action
    return utils.clone @_run()

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._run = (context) ->

  unless table = @_db._tables[@_tableId]
    throw Error "Table `#{@_tableId}` does not exist"

  context?.tableId = @_tableId

  unless action = @_action
    return table

  switch action[0]

    when GET
      return getRow table, action[1]

    when GET_ALL
      return getRows table, action[1]

    when INSERT
      return insertRows table, action[1], action[2]

    when DELETE
      return clearTable table

module.exports = Table

#
# Helpers
#

getRow = (table, id) ->

  if id is undefined
    throw Error "Argument 1 to get may not be `undefined`"

  if utils.isQuery id
    id = id._run()

  if (id is null) or isConstructor(id, Object)
    throw Error "Primary keys must be either a number, string, bool, pseudotype or array"

  row = table.find (row) -> row.id is id
  return row or null

getRows = (table, args) ->

  return [] unless args.length

  if isConstructor args[args.length - 1], Object
    key = args.pop().index

  key ?= "id"
  assertType key, String

  args.forEach (arg, index) ->

    if arg is undefined
      throw Error "Argument #{index} to getAll may not be `undefined`"

    if utils.isQuery arg
      args[index] = arg._run()

    if arg is null
      throw Error "Keys cannot be NULL"

    if isConstructor arg, Object
      throw Error (if key is "id" then "Primary" else "Secondary") + " keys must be either a number, string, bool, pseudotype or array"

  table.filter (row) ->
    for arg in args
      if isArray arg
        return yes if utils.equals arg, row[key]
      else if arg is row[key]
        return yes
    return no

# TODO: Support options argument.
insertRows = (table, rows) ->
  rows = utils.resolve rows
  rows = [rows] unless isArray rows

  errors = 0
  generated_keys = []

  for row in rows
    assertType row, Object

    # Check for duplicate primary keys.
    if row.hasOwnProperty "id"
      if getRow table, row.id
      then errors += 1
      else table.push row

    # Generate an `id` for rows without one.
    else
      generated_keys.push row.id = uuid()
      table.push row

  res = {errors}

  if errors > 0
    res.first_error = "Duplicate primary key `id`"

  res.inserted = rows.length - errors

  if generated_keys.length
    res.generated_keys = generated_keys

  return res

clearTable = (table) ->
  count = table.length
  table.length = 0
  return {deleted: count}
