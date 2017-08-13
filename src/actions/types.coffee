
isConstructor = require "isConstructor"

seqRE = /TABLE|SEQUENCE/

cache = Object.create null

types = exports

types.get = (actionId) ->
  return cache[actionId]

types.set = (values) ->
  for actionId, value of values
    cache[actionId] = value
  return

types.DATUM = "DATUM"

# Sequences are preserved.
# Tables are converted to sequences.
types.SEQUENCE = (ctx) ->
  return "SEQUENCE" if seqRE.test ctx.type
  return "DATUM"

# Tables/sequences are converted to a selection.
types.SELECTION = (ctx) ->
  return "SELECTION" if seqRE.test ctx.type
  return "DATUM"

# When the first argument is a number, tables/sequences are converted to a selection.
types.BRACKET = (ctx, args) ->
  unless isConstructor args[0], String
    return "SELECTION" if seqRE.test ctx.type
  return "DATUM"
