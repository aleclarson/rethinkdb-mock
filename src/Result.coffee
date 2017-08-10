
setProto = require "setProto"

utils = require "./utils"

define = Object.defineProperty

Result = (parent) ->
  self = (key) -> self.bracket key

  if utils.isQuery parent
    self._db = parent._db
    self._parent = parent
  else
    self._db = null
    self._parent = Query._expr parent

  return setProto self, Result.prototype

methods = {}

methods._eval = evalQuery = (ctx) ->
  result = @_parent._run()

  @_eval = (ctx) ->
    ctx.type = "DATUM"
    return result

  ctx.type = "DATUM"
  return result

methods._reset = ->
  delete @_eval
  return

Object.keys(methods).forEach (key) ->
  define Result.prototype, key,
    value: methods[key]
    writable: yes

module.exports = Result
