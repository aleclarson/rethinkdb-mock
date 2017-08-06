# TODO: Clone nested selections.

isConstructor = require "isConstructor"
sliceArray = require "sliceArray"
setType = require "setType"

actions = require "./actions"
utils = require "./utils"

{isArray} = Array

Query = (parent, type) ->
  self = (key) -> self.bracket arguments
  self._db = parent._db
  self._parent = parent
  self._type = type if type
  return setType self, Query

methods = Query.prototype

methods.default = (value) ->
  Query._default this, value

# Run a query once, and reuse its result.
Result = require("./Result")(Query)

# TODO: Support variadic arguments.
methods.do = (callback) ->
  Result(this)._do callback

variadic = (keys) ->
  keys.split(" ").forEach (key) ->
    methods[key] = ->
      @_then key, arguments
    return

variadic "eq ne gt lt ge le or and add sub mul div"

methods.nth = (index) ->
  @_then "nth", arguments

methods.bracket = (key) ->
  @_then "bracket", key

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

methods.update = (patch) ->
  @_then "update", arguments

methods.replace = (values) ->
  @_then "replace", arguments

methods.delete = ->
  @_then "delete"

methods.run = ->
  Promise.resolve()
    .then Query._run.bind null, this

methods.then = (onFulfilled) ->
  @run().then onFulfilled

methods.catch = (onRejected) ->
  @run().catch onRejected

module.exports = Query

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

methods._eval = (ctx, result) ->
  action = @_action

  if isConstructor action, String
    args = utils.resolve @_args
    arity = getArity(action)[1]

  ctx.type =
    if isConstructor @_type, Function
    then @_type.call this, ctx, args
    else @_type

  if isConstructor action, Function
    return action.call ctx, result

  if action is undefined
    return result

  if arity is 0
    return actions[@_action].call ctx, result

  if arity is 1
    return actions[@_action].call ctx, result, args[0]

  if arity is 2
    return actions[@_action].call ctx, result, args[0], args[1]

  return actions[@_action].call ctx, result, args

methods._run = (ctx) ->
  result = @_parent._run ctx
  unless ctx.error
    return @_eval ctx, result

Query._default = (parent, value) ->
  self = Query parent
  self._run = (ctx) ->
    result = self._parent._run ctx
    throw ctx.error unless isNullError ctx.error
    return result ? value
  return self

Query._expr = (expr) ->

  if expr is undefined
    throw Error "Cannot convert `undefined` with r.expr()"

  if isArray(expr) or isConstructor(expr, Object)
    keys = Object.keys expr
    for key in keys
      value = expr[key]

      unless utils.isQuery value
        expr[key] = Query._expr value

      else if value._type isnt "DATUM"
        throw Error "Expected type DATUM but found #{value._type}"

  return Query
    _run: -> utils.resolve expr

Query._run = (query, ctx) ->
  ctx = Object.assign {db: query._db}, ctx
  result = query._run ctx
  throw ctx.error if ctx.error

  delete ctx.db
  console.log "context = " + JSON.stringify ctx, null, 2

  if /TABLE|SEQUENCE|SELECTION/.test ctx.type
    return utils.clone result
  return result

#
# Helpers
#

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
    update: "DATUM"
    replace: "DATUM"
    delete: "DATUM"

  return (query) ->
    types[query._action]

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
    getAll: [1, Infinity]
    insert: [1, 2]
    update: [1, 1]
    replace: [1, 1]
    delete: [0, 0]

  return (action) ->
    arity[action]
