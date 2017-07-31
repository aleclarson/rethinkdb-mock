
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

methods.get = (id) ->
  self = Table @_db, @_tableId, [GET, id]
  return Selection self

methods.getAll = ->
  self = Table @_db, @_tableId, [GET_ALL, sliceArray arguments]
  return Sequence self

# TODO: Support inserting multiple rows.
# TODO: Support options argument.
methods.insert = (row) ->
  self = Table @_db, @_tableId, [INSERT, row]
  return Datum self

methods.delete = ->
  self = Table @_db, @_tableId, [DELETE]
  return Datum self

do ->
  keys = "do nth getField offsetsOf update filter orderBy limit slice pluck without fold".split " "
  keys.forEach (key) ->
    methods[key] = ->
      self = Sequence this
      return self[key].apply self, arguments

methods.run = ->
  Promise.resolve().then =>
    return @_run() if @_action
    return @_run().slice()

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._run = (context) ->

  unless table = @_db._tables[@_tableId]
    throw Error "Table `#{@_tableId}` does not exist"

  context?.tableId = @_tableId

  unless action = @_action
    return table

  switch action[0]

    when INSERT
      return insertRow table, action[1]

    when DELETE
      return deleteRows table

    when GET
      return getRow table, action[1]

    when GET_ALL
      return getRows table, action[1]

module.exports = Table

#
# Helpers
#

insertRow = (table, row) ->

  if hasId = row.hasOwnProperty "id"

    if (row.id is null) or isConstructor(row.id, Object)
      throw Error "Primary keys must be either a number, string, bool, pseudotype or array"

    if getRow table, row.id
      return {errors: 1, first_error: "Duplicate primary key `id`"}

  for key, value of row
    if value is undefined
      throw Error "Object field '#{key}' may not be undefined"

  res = {inserted: 1}
  unless hasId
    row.id = uuid()
    res.generated_keys = [row.id]

  table.push row
  return res

deleteRows = (table) ->
  count = table.length
  table.length = 0
  return {deleted: count}

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

  for arg, index in args

    if arg is undefined
      throw Error "Argument #{index} to getAll may not be `undefined`"

    if utils.isQuery arg
      args[index] = arg._run()

    if arg is null
      throw Error "Keys cannot be NULL"

    if isConstructor arg, Object
      throw Error (if key is "id" then "Primary" else "Secondary") + " keys must be either a number, string, bool, pseudotype or array"

  key ?= "id"
  table.filter (row) ->
    for arg in args
      if isArray arg
        return yes if utils.equals arg, row[key]
      else if arg is row[key]
        return yes
    return no
