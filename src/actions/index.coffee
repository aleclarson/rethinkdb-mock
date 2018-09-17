arity = require './arity'
types = require './types'
utils = require '../utils'

arity.set
  typeOf: arity.NONE

types.set
  typeOf: types.DATUM

actions =
  typeOf: utils.typeOf

utils.assertArity = (actionId, args) ->
  [min, max] = arity.get actionId

  if min == max
    if args.length != min
      throw Error "`#{actionId}` takes #{min} argument#{if min == 1 then "" else "s"}, #{args.length} provided"

  else if args.length < min
    throw Error "`#{actionId}` takes at least #{min} argument#{if min == 1 then "" else "s"}, #{args.length} provided"

  else if args.length > max
    throw Error "`#{actionId}` takes at most #{max} argument#{if max == 1 then "" else "s"}, #{args.length} provided"

wrapAction = (actionId, actionFn) ->
  maxArgs = arity.get(actionId)[1]

  if maxArgs == 0
    return (ctx, result) ->
      actionFn.call ctx, result

  if maxArgs == 1
    return (ctx, result, args) ->
      actionFn.call ctx, result, args[0]

  if maxArgs == 2
    return (ctx, result, args) ->
      actionFn.call ctx, result, args[0], args[1]

  return (ctx, result, args) ->
    actionFn.call ctx, result, args

[
  actions
  require './math'
  require './compare'
  require './object'
  require './array'
  require './table'
]
.forEach (actions) ->
  for actionId, actionFn of actions
    exports[actionId] =
      call: wrapAction actionId, actionFn
      arity: arity.get actionId
      type: types.get actionId
  return
