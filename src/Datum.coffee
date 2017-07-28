
setType = require "setType"

i = 1
DO = i++
EQ = i++
NE = i++
GT = i++
LT = i++
GE = i++
LE = i++
ADD = i++
SUB = i++
NTH = i++
MERGE = i++
FILTER = i++
DEFAULT = i++
GET_FIELD = i++
WITHOUT = i++
PLUCK = i++
DELETE = i++

Datum = (query) ->
  self = (key) -> self._get key
  self._query = query
  self._action = null
  return setType self, Datum

module.exports = Datum
