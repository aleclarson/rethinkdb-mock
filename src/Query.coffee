# TODO: Clone nested selections.

isConstructor = require "isConstructor"
sliceArray = require "sliceArray"
setType = require "setType"

actions = require "./actions"
utils = require "./utils"

{isArray} = Array

define = Object.defineProperty

Query = (parent, type) ->
  query = (key) -> query.bracket key

  if parent
    query._db = parent._db
    query._type = type or parent._type
    query._parent = parent
  else
    query._db = null
    query._type = type or null

  return setType query, Query

# Run a query once, and reuse its result.
Result = require("./Result")(Query)

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

methods.orderBy = (field) ->
  @_then "orderBy", arguments

methods.filter = (filter, options) ->
  @_then "filter", arguments

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

methods._then = (action, args) ->
  self = Query this, getType action
  self._action = action
  if args
    self._args = args
    self._parseArgs()
  return self

methods._parseArgs = ->
  arity = getArity @_action
  args =
    if isArray @_args
    then @_args
    else sliceArray @_args

  if args.length < arity[0]
    throw Error "`#{@_action}` takes at least #{arity[0]} argument#{if arity[0] is 1 then "" else "s"}, #{args.length} provided"

  if args.length > arity[1]
    throw Error "`#{@_action}` takes at most #{arity[1]} argument#{if arity[1] is 1 then "" else "s"}, #{args.length} provided"

  index = -1
  while ++index < args.length
    unless utils.isQuery args[index]
      args[index] = Query._expr args[index]

  @_args = args
  return

methods._eval = (ctx) ->
  action = @_action
  result = @_parent._eval ctx

  if isConstructor action, Function
    return action.call ctx, result

  if isConstructor action, String
    args = utils.resolve @_args
    arity = getArity(action)[1]
    result =
      if arity is 0
      then actions[action].call ctx, result
      else if arity is 1
      then actions[action].call ctx, result, args[0]
      else if arity is 2
      then actions[action].call ctx, result, args[0], args[1]
      else actions[action].call ctx, result, args

  ctx.type =
    if isConstructor @_type, Function
    then @_type.call this, ctx, args
    else @_type

  return result

methods._run = (ctx = {}) ->
  ctx.db = @_db
  result = @_eval ctx
  if /TABLE|SEQUENCE|SELECTION/.test ctx.type
    return utils.clone result
  return result

#
# Static methods
#

statics = {}

statics._do = (parent, args) ->

  unless args.length
    return parent

  self = Query()
  self._parent = parent

  last = args.pop()
  args.unshift parent

  if isConstructor last, Function
    args = args.slice(0, last.length).map Result
    query = last.apply null, args

    if query is undefined
      throw Error "Anonymous function returned `undefined`. Did you forget a `return`?"

    unless utils.isQuery query
      query = Query._expr query

    self._eval = (ctx) ->
      result = query._eval ctx
      args.forEach (arg) -> arg._reset()
      return result
    return self

  self._eval = (ctx) ->
    args.forEach utils.resolve
    utils.resolve last, ctx
  return self

statics._default = (parent, value) ->

  unless utils.isQuery value
    value = Query._expr value

  self = Query()
  self._parent = parent
  self._eval = (ctx) ->
    try result = parent._eval ctx
    catch error
      throw error unless isNullError error
    return result ? value._eval ctx
  return self

statics._branch = (cond, args) ->

  if args.length % 2
    throw Error "`branch` cannot be called with an even number of arguments"

  lastIndex = args.length - 1

  self = Query()
  self._parent = cond
  self._eval = (ctx) ->

    unless isFalse cond._eval {}
      return utils.resolve args[0], ctx

    index = -1
    while (index += 2) isnt lastIndex
      unless isFalse utils.resolve args[index]
        return utils.resolve args[index + 1], ctx

    return utils.resolve args[lastIndex], ctx
  return self

statics._expr = (expr) ->

  if expr is undefined
    throw Error "Cannot convert `undefined` with r.expr()"

  if isConstructor(expr, Number) and not isFinite expr
    throw Error "Cannot convert `#{expr}` to JSON"

  if utils.isQuery expr
    return expr

  self = Query null, "DATUM"

  if isArrayOrObject expr
    values = expr
    expr = if isArray values then [] else {}
    Object.keys(values).forEach (key) ->
      value = values[key]

      unless utils.isQuery value
        expr[key] = Query._expr value
        return

      if /DATUM|SELECTION/.test value._type
        expr[key] = value
        return

      throw Error "Expected type DATUM but found #{value._type}"

    self._eval = (ctx) ->
      ctx.type = @_type
      return utils.resolve expr

  else
    self._eval = (ctx) ->
      ctx.type = @_type
      return expr

  return self

#
# Exports
#

Object.keys(methods).forEach (key) ->
  define Query.prototype, key,
    value: methods[key]
    writable: yes

Object.keys(statics).forEach (key) ->
  define Query, key,
    value: statics[key]

module.exports = Query

#
# Helpers
#

isFalse = (value) ->
  (value is null) or (value is false)

isArrayOrObject = (value) ->
  isArray(value) or isConstructor(value, Object)

isNullError = (error) ->
  !error or /(Index out of bounds|No attribute|null)/i.test error.message

getType = do ->

  # Sequences are preserved.
  # Tables are converted to sequences.
  sequential = (ctx) ->
    return "SEQUENCE" if /TABLE|SEQUENCE/.test ctx.type
    return "DATUM"

  types =
    eq: "DATUM"
    ne: "DATUM"
    gt: "DATUM"
    lt: "DATUM"
    ge: "DATUM"
    le: "DATUM"
    or: "DATUM"
    and: "DATUM"
    add: "DATUM"
    sub: "DATUM"
    mul: "DATUM"
    div: "DATUM"

    nth: (ctx) ->
      return "SELECTION" if /TABLE|SEQUENCE/.test ctx.type
      return "DATUM"

    # For tables and sequences, an index argument results in a selection.
    bracket: (ctx, args) ->
      unless isConstructor args[0], String
        return "SELECTION" if /TABLE|SEQUENCE/.test ctx.type
      return "DATUM"

    getField: "DATUM"
    hasFields: sequential
    offsetsOf: "DATUM"
    orderBy: sequential
    filter: sequential
    fold: null # TODO: Determine `fold` result type.
    count: "DATUM"
    limit: sequential
    slice: sequential
    merge: "DATUM"
    pluck: "DATUM"
    without: "DATUM"
    typeOf: "DATUM"
    update: "DATUM"
    replace: "DATUM"
    delete: "DATUM"

  return (action) ->
    types[action]

getArity = do ->

  arity =
    eq: [1, Infinity]
    ne: [1, Infinity]
    gt: [1, Infinity]
    lt: [1, Infinity]
    ge: [1, Infinity]
    le: [1, Infinity]
    or: [1, Infinity]
    and: [1, Infinity]
    add: [1, Infinity]
    sub: [1, Infinity]
    mul: [1, Infinity]
    div: [1, Infinity]
    nth: [1, 1]
    bracket: [1, 1]
    getField: [1, 1]
    hasFields: [1, Infinity]
    offsetsOf: [1, 1]
    orderBy: [1, 1]
    filter: [1, 2]
    fold: [2, 2]
    count: [0, 0]
    limit: [1, 1]
    slice: [1, Infinity]
    merge: [1, Infinity]
    pluck: [1, Infinity]
    without: [1, Infinity]
    typeOf: [0, 0]
    getAll: [1, Infinity]
    insert: [1, 2]
    update: [1, 1]
    replace: [1, 1]
    delete: [0, 0]

  return (action) ->
    arity[action]
