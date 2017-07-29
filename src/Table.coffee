
isConstructor = require "isConstructor"
assertType = require "assertType"
sliceArray = require "sliceArray"
setType = require "setType"
Either = require "Either"

Selection = require "./Selection"
Sequence = require "./Sequence"
Datum = require "./Datum"
uuid = require "./uuid"

{isArray} = Array

i = 1
GET = i++
GET_ALL = i++
INSERT = i++
DELETE = i++

Table = (db, tableId, action) ->
  self = (value) -> Sequence(self)._get value
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

  if row.id? and getRow table, row.id
    return {errors: 1, first_error: "Duplicate primary key `id`"}

  res = {inserted: 1}
  unless row.id?
    row.id = uuid()
    res.generated_keys = [row.id]

  table.push row
  return res

deleteRows = (table) ->
  count = table.length
  table.length = 0
  return {deleted: count}

getRow = (table, id) ->
  row = table.find (row) -> row.id is id
  return row or null

getRows = (table, args) ->
  return [] unless args.length

  if isConstructor args[args.length - 1], Object
    key = args.pop().index

  argType = Either Number, String, Boolean, Array
  for arg, index in args
    assertType arg, argType, "args[#{index}]"

  key ?= "id"
  table.filter (row) ->
    for arg in args
      if isArray arg
        return yes if utils.arrayEquals arg, row[key]
      else if arg is row[key]
        return yes
    return no
