
rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "datum.default()", ->

  it "replaces null values with the given value", ->
    db.expr(null).default 1
    .then (res) ->
      expect(res).toBe 1

  it "avoids 'missing attribute' errors", ->
    db.expr({})("key").default 1
    .then (res) ->
      expect(res).toBe 1

  it "avoids 'index out of bounds' errors", ->
    db.expr([])(0).default 1
    .then (res) ->
      expect(res).toBe 1

  it "avoids 'null not an object' errors", ->
    db.expr(null)("key").default 1
    .then (res) ->
      expect(res).toBe 1

  it "avoids 'null not a sequence' errors", ->
    db.expr(null)(0).default 1
    .then (res) ->
      expect(res).toBe 1

  it "does not avoid other errors", ->
    db.expr(undefined).default 1
    .then (res) ->
      expect(res).toBe undefined
    .catch (error) ->
      expect(error?).toBe true

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

  it "compares based on typeof (time > string > object > number > null > bool > array)", ->
    db.expr(new Date).gt "", {}, 0, null, false, []
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

  it "compares based on typeof (array < bool < null < number < object < string < time)", ->
    db.expr([]).lt true, null, 1, {}, "", new Date
    .then (res) ->
      expect(res).toBe true

describe "datum.or()", ->

  it "returns false if all values are false", ->
    db.expr(false).or false, false
    .then (res) ->
      expect(res).toBe false

  it "returns the first value that is not false", ->

    db.expr(false).or 1, 2, false
    .then (res) ->
      expect(res).toBe 1

      db.expr(false).or true, 1
      .then (res) ->
        expect(res).toBe true

describe "datum.and()", ->

  it "returns false if at least one value is false", ->
    db.expr(true).and false, true, 1
    .then (res) ->
      expect(res).toBe false

  it "returns the last value if all other values are not false", ->

    db.expr(true).and true, 1
    .then (res) ->
      expect(res).toBe 1

      db.expr(true).and true, true
      .then (res) ->
        expect(res).toBe true
