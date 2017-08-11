
cache = Object.create null

arity = exports

arity.get = (actionId) ->
  return cache[actionId]

arity.set = (values) ->
  for actionId, value of values
    cache[actionId] = value
  return

arity.NONE = [0, 0]
arity.ONE = [1, 1]
arity.ONE_PLUS = [1, Infinity]
arity.ONE_TWO = [1, 2]
arity.ONE_THREE = [1, 3]
arity.TWO = [2, 2]
