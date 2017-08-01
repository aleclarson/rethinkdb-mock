
rethinkdb = require ".."

db = rethinkdb()

describe "db.expr()", ->

  it "converts a literal into a query", ->
    db.expr 1
    .then (res) ->
      expect(res).toBe 1

  it "clones objects", ->
    db.expr obj = {a: 1}
    .then (res) ->
      expect(res.a).toBe 1
      expect(res).not.toBe obj

  it "clones arrays", ->
    db.expr arr = [1, 2]
    .then (res) ->
      expect(res).toEqual arr
      expect(res).not.toBe arr

  # it "supports nested queries", ->

describe "db.object()", ->

  it "creates an object from an array of keys and values", ->
    db.object "id", 1, "name", "Alec"
    .then (object) ->
      expect(object.id).toBe 1
      expect(object.name).toBe "Alec"

  it "throws an error if a key is not a string", ->
    expect -> db.object("id", 1, 2, 3)._run()
    .toThrowError "Expected a String!"

  it "throws an error if a key has no value", ->
    expect -> db.object("id", undefined)._run()
    .toThrowError "Argument 1 to object may not be `undefined`"

  # it "supports nested queries", ->
