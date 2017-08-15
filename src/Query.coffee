
isConstructor = require "isConstructor"
sliceArray = require "sliceArray"
setProto = require "setProto"

actions = require "./actions"
utils = require "./utils"

{isArray} = Array

define = Object.defineProperty
seqRE = /TABLE|SELECTION<ARRAY>/

Query = (parent, type) ->
  query = (key) -> query.bracket key

  if parent
    query._db = parent._db
    query._type = type or parent._type
    query._parent = parent
    query._lazy = true if parent._lazy
  else
    query._db = null
    query._type = type or null

  return setProto query, Query.prototype

# Define methods with infinite arity.
variadic = (keys) ->
  keys.split(" ").forEach (key) ->
    methods[key] = ->
      @_then key, arguments
    return

#
# Public methods
#

methods = {}

methods.default = (value) ->
  Query._default this, value

methods.do = ->
  args = sliceArray arguments
  return Query._do this, args

variadic "eq ne gt lt ge le or and add sub mul div"

methods.nth = (index) ->
  @_then "nth", arguments

methods.bracket = (key) ->
  @_then "bracket", arguments

methods.getField = (field) ->
  @_then "getField", arguments

variadic "hasFields"

methods.offsetsOf = (value) ->
  @_then "offsetsOf", arguments

methods.contains = (value) ->
  @_then "contains", arguments

methods.orderBy = (field) ->
  @_then "orderBy", arguments

# TODO: Support mapping over multiple sequences simultaneously.
methods.map = (query) ->

  if utils.isQuery query
    unless query._lazy
      throw Error "Expected `r.row` or a FUNCTION, but found #{query._type}"

  else if isConstructor query, Function
    query = Query._expr query Query._row

  @_then "map", arguments

methods.filter = (filter, options) ->

  if isConstructor filter, Function
    filter = Query._expr filter Query._row

  @_then "filter", arguments

methods.isEmpty = ->
  @_then "isEmpty"

methods.count = ->
  @_then "count"

methods.skip = (count) ->
  @_then "skip", arguments

methods.limit = (count) ->
  @_then "limit", arguments

variadic "slice merge pluck without"

methods.typeOf = ->
  @_then "typeOf"

methods.branch = ->
  args = sliceArray arguments
  if args.length < 2
    throw Error "`branch` takes at least 2 arguments, #{args.length} provided"
  return Query._branch this, args

methods.update = (patch) ->
  @_then "update", arguments

methods.replace = (values) ->
  @_then "replace", arguments

methods.delete = ->
  @_then "delete"

methods.run = ->
  Promise.resolve()
    .then @_run.bind this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods.catch = (onRejected) ->
  @run().catch onRejected

#
# Internal
#

methods._then = (actionId, args) ->
  query = Query this, actions[actionId].type
  query._actionId = actionId
  if args
    query._args = args
    query._parseArgs()
  return query

methods._parseArgs = ->
  args = utils.cloneArray @_args

  if containsQuery args
    @_args = Query._args args
    return

  utils.assertArity @_actionId, args
  @_args = args
  return

methods._eval = (ctx) ->
  actionId = @_actionId
  result = @_parent._eval ctx

  args = @_args
  if utils.isQuery args
    args = args._run()
    utils.assertArity actionId, args

  if isConstructor actionId, String
    result = actions[actionId].call ctx, result, args

  ctx.type =
    if isConstructor @_type, Function
    then @_type.call this, ctx, args
    else @_type

  return result

methods._run = (ctx = {}) ->
  ctx.db = @_db
  result = @_eval ctx
  if /TABLE|SELECTION/.test ctx.type
    return utils.clone result
  return result

#
# Static methods
#

statics = {}

# TODO: Evaluate queries from last to first.
statics._do = (parent, args) ->

  unless args.length
    return parent

  query = Query()
  query._parent = parent

  last = args.pop()
  args.unshift parent

  if isConstructor last, Function
    {length} = last

    # Allow zero arguments, where none of the given queries are evaluated.
    # Otherwise, enforce the arity of the given function.
    if (length > 0) and (length isnt args.length)
      throw Error "Expected function with #{plural "argument", args.length} but found function with #{plural "argument", last.length}"

    # TODO: Currently, the given function is called more than once.
    #   This is different from `rethinkdbdash`, but easier to implement.
    #   The ideal solution calls the given function once, but also ensures
    #   the given queries are all called once (no more, no less).
    query._eval = (ctx) ->

      # Run the given queries once (no more, no less)
      # only if the given function is using them.
      value =
        if length
        then last.apply null, args.map runOnce
        else last()

      if value is undefined
        throw Error "Anonymous function returned `undefined`. Did you forget a `return`?"

      return utils.resolve value, ctx
    return query

  # TODO: Support `r.row` when no function is given.
  query._eval = (ctx) ->
    # The given queries are evaluated from last to first.
    value = utils.resolve last, ctx
    index = args.length
    while --index >= 0
      utils.resolve args[index]
    return value
  return query

statics._default = (parent, value) ->

  unless utils.isQuery value
    value = Query._expr value

  query = Query()
  query._parent = parent
  query._eval = (ctx) ->
    try result = parent._eval ctx
    catch error
      throw error unless isNullError error
    return result ? value._eval ctx
  return query

statics._branch = (cond, args) ->

  if args.length % 2
    throw Error "`branch` cannot be called with an even number of arguments"

  lastIndex = args.length - 1

  query = Query()
  query._parent = cond
  query._eval = (ctx) ->

    unless isFalse cond._eval {}
      return utils.resolve args[0], ctx

    index = -1
    while (index += 2) isnt lastIndex
      unless isFalse utils.resolve args[index]
        return utils.resolve args[index + 1], ctx

    return utils.resolve args[lastIndex], ctx
  return query

statics._expr = (expr) ->

  if expr is undefined
    throw Error "Cannot convert `undefined` with r.expr()"

  if isConstructor(expr, Number) and not isFinite expr
    throw Error "Cannot convert `#{expr}` to JSON"

  if utils.isQuery expr
    return expr

  query = Query null, "DATUM"

  if isArrayOrObject expr
    values = expr
    expr = if isArray values then [] else {}
    utils.each values, (value, key) ->

      unless utils.isQuery value
        value = Query._expr value

      else if seqRE.test value._type
        throw Error "Expected type DATUM but found #{value._type}"

      query._lazy = true if value._lazy
      expr[key] = value
      return

    query._eval = (ctx) ->
      ctx.type = @_type
      return utils.resolve expr, ctx

  else
    query._eval = (ctx) ->
      ctx.type = @_type
      return expr

  return query

statics._row = do ->
  query = Query null, "ROW"
  query._lazy = true
  query._eval = (ctx) ->
    ctx.type = "DATUM"
    return ctx.row if ctx.row
    throw Error "r.row is not defined in this context"
  return query

# TODO: Detect queries nested in `r.expr`
statics._args = (args) ->
  args = args.map Query._expr

  query = Query null, "ARGS"
  query._eval = (ctx) ->
    ctx.type = "DATUM"

    values = []
    args.forEach (arg) ->

      if arg._lazy
        values.push arg
        return

      if arg._type is "ARGS"
        values = values.concat arg._run()
        return

      values.push arg._run()
      return

    return values
  return query

#
# Exports
#

utils.each methods, (method, key) ->
  define Query.prototype, key,
    value: method
    writable: true

utils.each statics, (value, key) ->
  define Query, key, {value}

module.exports = Query

#
# Helpers
#

plural = (noun, count) ->
  return "1 " + noun if count is 1
  return count + " " + noun + "s"

runOnce = (arg) ->
  if utils.isQuery arg
  then Query._expr arg._run()
  else Query._expr arg

isFalse = (value) ->
  (value is null) or (value is false)

isArrayOrObject = (value) ->
  isArray(value) or isConstructor(value, Object)

isNullError = (error) ->
  !error or /(Index out of bounds|No attribute|null)/i.test error.message

hasQuery = (object) ->
  for key, value of object
    if isConstructor value, Object
      return yes if hasQuery value
    else if isArray value
      return yes if containsQuery value
    else if utils.isQuery value
      return yes
  return no

containsQuery = (array) ->
  for value in array
    if isConstructor value, Object
      return yes if hasQuery value
    else if isArray value
      return yes if containsQuery value
    else if utils.isQuery value
      return yes
  return no
