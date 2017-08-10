
isConstructor = require "isConstructor"
sliceArray = require "sliceArray"
setProto = require "setProto"

actions = require "./actions"
Result = require "./Result"
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

methods.filter = (filter, options) ->
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

methods._then = (action, args) ->
  query = Query this, getType action
  query._action = action
  if args
    query._args = args
    query._parseArgs()
  return query

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

  query = Query()
  query._parent = parent

  last = args.pop()
  args.unshift parent

  if isConstructor last, Function
    args = args.slice(0, last.length).map Result
    value = last.apply null, args

    if value is undefined
      throw Error "Anonymous function returned `undefined`. Did you forget a `return`?"

    unless utils.isQuery value
      value = Query._expr value

    query._eval = (ctx) ->
      result = value._eval ctx
      args.forEach (arg) -> arg._reset()
      return result
    return query

  query._eval = (ctx) ->
    args.forEach utils.resolve
    utils.resolve last, ctx
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
    Object.keys(values).forEach (key) ->
      value = values[key]

      unless utils.isQuery value
        expr[key] = Query._expr value
        return

      if /DATUM|SELECTION/.test value._type
        expr[key] = value
        return

      throw Error "Expected type DATUM but found #{value._type}"

    query._eval = (ctx) ->
      ctx.type = @_type
      return utils.resolve expr

  else
    query._eval = (ctx) ->
      ctx.type = @_type
      return expr

  return query

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
  DATUM = "DATUM"

  seqRE = /TABLE|SEQUENCE/

  # Sequences are preserved.
  # Tables are converted to sequences.
  sequential = (ctx) ->
    return "SEQUENCE" if seqRE.test ctx.type
    return DATUM

  types =
    eq: DATUM
    ne: DATUM
    gt: DATUM
    lt: DATUM
    ge: DATUM
    le: DATUM
    or: DATUM
    and: DATUM
    add: DATUM
    sub: DATUM
    mul: DATUM
    div: DATUM

    nth: (ctx) ->
      return "SELECTION" if seqRE.test ctx.type
      return DATUM

    # For tables and sequences, an index argument results in a selection.
    bracket: (ctx, args) ->
      unless isConstructor args[0], String
        return "SELECTION" if seqRE.test ctx.type
      return DATUM

    getField: DATUM
    hasFields: sequential
    offsetsOf: DATUM
    contains: DATUM
    orderBy: sequential
    filter: sequential
    fold: null # TODO: Determine `fold` result type.
    isEmpty: DATUM
    count: DATUM
    skip: sequential
    limit: sequential
    slice: sequential
    merge: DATUM
    pluck: DATUM
    without: DATUM
    typeOf: DATUM
    update: DATUM
    replace: DATUM
    delete: DATUM

  return (action) ->
    types[action]

getArity = do ->
  none = [0, 0]
  one = [1, 1]
  two = [2, 2]
  oneTwo = [1, 2]
  onePlus = [1, Infinity]

  arity =
    eq: onePlus
    ne: onePlus
    gt: onePlus
    lt: onePlus
    ge: onePlus
    le: onePlus
    or: onePlus
    and: onePlus
    add: onePlus
    sub: onePlus
    mul: onePlus
    div: onePlus
    nth: one
    bracket: one
    getField: one
    hasFields: onePlus
    offsetsOf: one
    contains: one
    orderBy: one
    filter: oneTwo
    fold: two
    isEmpty: none
    count: none
    skip: one
    limit: one
    slice: onePlus
    merge: onePlus
    pluck: onePlus
    without: onePlus
    typeOf: none
    getAll: onePlus
    insert: oneTwo
    update: one
    replace: one
    delete: none

  return (action) ->
    arity[action]
