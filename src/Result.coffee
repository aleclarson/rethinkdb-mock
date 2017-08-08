
setKind = require "setKind"
setType = require "setType"

utils = require "./utils"

define = Object.defineProperty

module.exports = (Query) ->

  Result = (parent) ->
    self = (key) -> self.bracket key
    self._db = parent._db
    self._parent = parent
    return setType self, Result

  setKind Result, Query

  methods = {}

  methods._do = (callback) ->
    query = callback this

    unless utils.isQuery query
      query = Query._expr query

    @_query = query
    return this

  methods._eval = evalQuery = (ctx) ->
    @_result = @_parent._eval ctx

    if /TABLE|SEQUENCE/.test ctx.type
      throw Error "Expected type DATUM but found #{ctx.type}"

    @_context = ctx
    @_eval = getResult
    result = @_query._eval {}
    @_eval = evalQuery

    delete @_result
    delete @_context

    return result

  getResult = (ctx) ->
    Object.assign ctx, @_context
    return @_result

  Object.keys(methods).forEach (key) ->
    define Result.prototype, key,
      value: methods[key]
      writable: yes

  return Result
