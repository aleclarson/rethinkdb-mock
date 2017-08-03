
rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "datum.default()", ->

  it "replaces null values with the given value", ->
    query = db.expr(null).default 1
    expect(query._run()).toBe 1

  it "avoids 'missing attribute' errors", ->
    query = db.expr({})("key").default 1
    expect(query._run()).toBe 1

  it "avoids 'index out of bounds' errors", ->
    query = db.expr([])(0).default 1
    expect(query._run()).toBe 1

  it "avoids 'null not an object' errors", ->
    query = db.expr(null)("key").default 1
    expect(query._run()).toBe 1

  it "avoids 'null not a sequence' errors", ->
    query = db.expr(null)(0).default 1
    expect(query._run()).toBe 1

  it "does not avoid other errors", ->
    query = db.expr(undefined).default 1
    expect -> query._run()
    .toThrow()

  it "uses the first default value in a series of `default` calls", ->
    db.expr(null).default(1).default 2
    .then (res) ->
      expect(res).toBe 1

describe "datum.do()", ->

  beforeAll ->
    db.init users: []

  it "calls the given function immediately", ->
    spy = jasmine.createSpy()
    db.expr(1).do -> spy() or 1
    expect(spy.calls.count()).toBe 1

  it "supports the function returning a literal", ->
    db.expr(1).do -> 0
    .then (res) ->
      expect(res).toBe 0

  it "supports the function returning a query", ->
    db.expr(1).do -> db.expr 0
    .then (res) ->
      expect(res).toBe 0

  it "only runs its parent query once", ->
    db.table("users").insert {id: 1}
    .do (res) -> res("inserted").eq(1).and res("errors").eq(0)
    .then (res) ->
      expect(res).toBe true
      expect(db._tables.users.length).toBe 1

describe "datum.equals()", ->

  it "returns true if two values are equal", ->
    db.expr(1).eq(1).then (res) ->
      expect(res).toBe true

  it "returns true if all values are equal", ->
    db.expr(1).eq(1, 1).then (res) ->
      expect(res).toBe true

  it "returns false if any value is not equal", ->
    db.expr(1).eq(1, 2, 1).then (res) ->
      expect(res).toBe false

  it "compares objects recursively", ->
    obj1 = {a: {b: {c: 1}}}
    obj2 = {a: {b: {c: 1}}}
    db.expr(obj1).eq(obj2).then (res) ->
      expect(res).toBe true

  it "compares arrays recursively", ->
    arr1 = [1, [2, [3]]]
    arr2 = [1, [2, [3]]]
    db.expr(arr1).eq(arr2).then (res) ->
      expect(res).toBe true

  it "supports nested queries", ->
    obj1 = { a: db.expr(2) }
    obj2 = { a: db.expr(1).add(1) }
    db.expr(obj1).eq(obj2).then (res) ->
      expect(res).toBe true

describe "datum.gt()", ->

  it "returns true if each value is greater than the next value", ->
    db.expr(1).gt 0, -1
    .then (res) ->
      expect(res).toBe true

  it "returns false if any value is not greater than the next value", ->
    db.expr(1).gt 0, 2
    .then (res) ->
      expect(res).toBe false

  # NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
  it "compares based on typeof (string > time > object > number > null > bool > array)", ->
    db.expr("").gt new Date, {}, 0, null, false, []
    .then (res) ->
      expect(res).toBe true

describe "datum.lt()", ->

  it "returns true if each value is less than the next value", ->
    db.expr(0).lt 1, 2, 3
    .then (res) ->
      expect(res).toBe true

  it "returns false if any value is not less than the next value", ->
    db.expr(0).lt 1, 2, -3
    .then (res) ->
      expect(res).toBe false

  # NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
  it "compares based on typeof (array < bool < null < number < object < time < string)", ->
    db.expr([]).lt true, null, 1, {}, new Date, ""
    .then (res) ->
      expect(res).toBe true

describe "datum.or()", ->

  it "returns the last value if all other values are false or null", ->

    query = db.expr(false).or null, false
    expect(query._run()).toBe false

    query = db.expr(false).or false, null
    expect(query._run()).toBe null

  it "returns the first value that is not false or null", ->

    query = db.expr(false).or null, 1, 2
    expect(query._run()).toBe 1

    query = db.expr(null).or true, 1
    expect(query._run()).toBe true

describe "datum.and()", ->

  it "returns the last value if all other values are not false or null", ->
    query = db.expr(1).and 2, 3
    expect(query._run()).toBe 3

  it "returns the first value that is false or null", ->

    query = db.expr(true).and false, true
    expect(query._run()).toBe false

    query = db.expr(1).and null, 2
    expect(query._run()).toBe null
