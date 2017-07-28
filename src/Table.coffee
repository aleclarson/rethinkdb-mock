
Promise = require "Promise"
setType = require "setType"
Either = require "Either"
isType = require "isType"

Selection = require "./Selection"
Sequence = require "./Sequence"
tables = require "./tables"
Datum = require "./Datum"
uuid = require "./uuid"

i = 1
GET = i++
GET_ALL = i++
INSERT = i++
DELETE = i++

Table = (tableId, action) ->
  self = (value) -> Sequence(self)._get value
  self._tableId = tableId
  self._action = action or null
  return setType self, Table

methods = Table.prototype

methods.get = (id) ->
  @_action = [GET, id]
  return Selection this

methods.getAll = ->
  @_action = [GET_ALL, arguments]
  return Sequence this

methods.insert = (row) ->
  @_action = [INSERT, row]
  return Datum this

methods.delete = ->
  @_action = [DELETE]
  return Datum this

do ->
  keys = ["nth", "getField", "update", "filter", "fold", "pluck", "without", "limit", "orderBy"]
  keys.forEach (key) ->
    methods[key] = ->
      query = Sequence this
      @_actions.push query
      return query[key].apply query, arguments

methods.run = ->
  Promise.try =>
    result = @_run()
    if @_action
    then result
    else result.slice()

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods._push = (action) ->
  self = Table @_tableId
  self._action = action
  return self

methods._run = ->

  unless table = tables.get @_tableId
    throw Error "Table '#{@_tableId}' does not exist"

  unless @_action
    return table

  switch @_action[0]

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
  table.find (row) -> row.id is id

getRows = (table, args) ->
  return [] unless args.length

  if isType args[args.length - 1], Object
    key = args.pop().index

  argType = Either Number, String, Boolean, Array
  for arg, index in args
    assertType arg, argType, "args[#{index}]"

  key ?= "id"
  table.filter (row) ->
    for arg in args
      if isType arg, Array
        return yes if utils.arrayEquals arg, row[key]
      else if arg is row[key]
        return yes
    return no
