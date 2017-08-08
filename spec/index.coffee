
rethinkdb = require ".."

db = rethinkdb()

describe "db.expr()", ->

  it "converts a literal into a query", ->
    expect(1).toBe db.expr(1)._run()

  it "throws if the value is undefined", ->
    expect -> db.expr undefined
    .toThrowError "Cannot convert `undefined` with r.expr()"

  it "throws if the value is an imaginary number", ->

    expect -> db.expr NaN
    .toThrowError "Cannot convert `NaN` to JSON"

    expect -> db.expr Infinity
    .toThrowError "Cannot convert `Infinity` to JSON"

    expect -> db.expr -Infinity
    .toThrowError "Cannot convert `-Infinity` to JSON"

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

  it "creates an object from key-value pairs", ->
    query = db.object "a", 1, "b", 2
    expect(query._run()).toEqual {a: 1, b: 2}

  it "throws if a key is not a string", ->
    query = db.object "a", 1, null, 2
    expect -> query._run()
    .toThrowError "Expected type STRING but found NULL"

  it "throws if a key has no value", ->
    expect -> db.object "a", 1, "b"
    .toThrowError "Expected an even number of arguments"

  # it "supports nested queries", ->

describe "db.typeOf()", ->

  it "returns NULL for null literals", ->
    query = db.typeOf null
    expect(query._run()).toBe "NULL"

  it "returns BOOL for boolean literals", ->
    query = db.typeOf true
    expect(query._run()).toBe "BOOL"

  it "returns STRING for string literals", ->
    query = db.typeOf ""
    expect(query._run()).toBe "STRING"

  it "returns NUMBER for number literals", ->
    query = db.typeOf 0
    expect(query._run()).toBe "NUMBER"

  it "returns ARRAY for array literals", ->
    query = db.typeOf []
    expect(query._run()).toBe "ARRAY"

  it "returns OBJECT for object literals", ->
    query = db.typeOf {}
    expect(query._run()).toBe "OBJECT"
