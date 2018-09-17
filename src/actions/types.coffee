seqRE = /TABLE|SELECTION<ARRAY>/

cache = Object.create null

types = exports

types.get = (actionId) ->
  return cache[actionId]

types.set = (values) ->
  for actionId, value of values
    cache[actionId] = value
  return

types.DATUM = 'DATUM'

# TABLE becomes SELECTION<ARRAY>
types.SEQUENCE = (ctx) ->
  return 'SELECTION<ARRAY>' if seqRE.test ctx.type
  return 'DATUM'

# TABLE and SELECTION<ARRAY> become SELECTION
types.SELECTION = (ctx) ->
  return 'SELECTION' if seqRE.test ctx.type
  return 'DATUM'

# When `args[0]` is numeric, TABLE and SELECTION<ARRAY> become SELECTION
types.BRACKET = (ctx, args) ->
  if typeof args[0] != 'string'
    return 'SELECTION' if seqRE.test ctx.type
  return 'DATUM'
