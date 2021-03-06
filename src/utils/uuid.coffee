TypeError = require 'type-error'
uuid_v4 = require 'uuid/v4'
uuid_v5 = require 'uuid/v5'

namespace = '91461c99-f89d-49d2-af96-d8e2e14e9b58'

module.exports = (value) ->
  if arguments.length
    if typeof value != 'string'
      throw TypeError String, value
    return uuid_v5 value, namespace
  return uuid_v4()
