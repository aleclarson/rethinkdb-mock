
arity = require "./arity"
types = require "./types"
utils = require "../utils"

arity.set
  typeOf: arity.NONE

types.set
  typeOf: types.DATUM

actions = exports

actions.typeOf = utils.typeOf

[
  require "./math"
  require "./compare"
  require "./object"
  require "./array"
  require "./table"
]
.forEach (exports) ->
  Object.assign actions, exports
