
rethinkdb = require ".."

db = rethinkdb()

describe "db.expr()", ->

  it "converts a literal into a query", ->
    expect(1).toBe db.expr(1)._run()

  it "clones objects", ->
    query = db.expr obj = {a: 1}
    res = query._run()
    expect(res).toEqual obj
    expect(res).not.toBe obj

  it "clones arrays", ->
    query = db.expr arr = [1, 2]
    res = query._run()
    expect(res).toEqual arr
    expect(res).not.toBe arr

  # it "supports nested queries", ->

describe "db.object()", ->

  it "creates an object from an array of keys and values", ->
    res = db.object("id", 1, "name", "Alec")._run()
    expect(res.id).toBe 1
    expect(res.name).toBe "Alec"

  it "throws an error if a key is not a string", ->
    expect -> db.object("id", 1, 2, 3)._run()
    .toThrowError "Expected a String!"

  it "throws an error if a key has no value", ->
    expect -> db.object("id", undefined)._run()
    .toThrowError "Argument 1 to object may not be `undefined`"

  # it "supports nested queries", ->
