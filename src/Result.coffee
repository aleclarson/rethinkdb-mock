
setType = require "setType"

utils = require "./utils"

module.exports = (Query) ->

  Result = (parent) ->
    self = (key) -> self.bracket arguments
    self._db = parent._db
    self._parent = parent
    return setType self, Result

  methods = Result.prototype
  Object.setPrototypeOf methods, Query.prototype

  methods._do = (callback) ->
    query = callback this

    unless utils.isQuery query
      query = utils.expr query

    @_query = query
    return this

  methods._run = run = (ctx) ->

    @_context = ctx
    @_result = @_parent._run ctx
    if /TABLE|SEQUENCE/.test ctx.type
      throw Error "Expected type DATUM but found #{ctx.type}"

    @_run = getResult
    result = @_query._run ctx
    @_run = run

    @_result = undefined
    return result

  getResult = (ctx) ->
    Object.assign ctx, @_context
    return @_result

  return Result
