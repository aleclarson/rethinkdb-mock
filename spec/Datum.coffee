
utils = require "../js/utils"

describe "query._type === DATUM", ->

  beforeAll ->
    db.init users: []

  describe ".default()", ->

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
      query = db.expr(1).add("").default 1
      expect -> query._run()
      .toThrow()

    it "uses the first default value in a series of `default` calls", ->
      query = db.expr(null).default(1).default 2
      expect(query._run()).toBe 1

    # it "can be used in a nested query", ->

  describe ".do()", ->

    it "calls the given function immediately", ->
      spy = jasmine.createSpy()
      db.expr(1).do -> spy() or 1
      expect(spy.calls.count()).toBe 1

    it "supports the function returning a literal", ->
      query = db.expr(1).do -> 0
      expect(query._run()).toBe 0

    it "supports the function returning a query", ->
      query = db.expr(1).do -> db.expr(0).add(2)
      expect(query._run()).toBe 2

    it "only runs its parent query once", ->
      query = db.table("users").insert {id: 1}
        .do (res) -> res("inserted").eq(1).and res("errors").eq(0)
      expect(query._run()).toBe true
      expect(db._tables.users.length).toBe 1

  describe ".equals()", ->

    it "returns true if two values are equal", ->
      query = db.expr(1).eq 1
      expect(query._run()).toBe true

    it "returns true if all values are equal", ->
      query = db.expr(1).eq 1, 1
      expect(query._run()).toBe true

    it "returns false if any value is not equal", ->
      query = db.expr(1).eq 1, 2, 1
      expect(query._run()).toBe false

    it "compares objects recursively", ->
      obj1 = {a: {b: {c: 1}}}
      obj2 = {a: {b: {c: 1}}}
      query = db.expr(obj1).eq obj2
      expect(query._run()).toBe true

    it "compares arrays recursively", ->
      arr1 = [1, [2, [3]]]
      arr2 = [1, [2, [3]]]
      query = db.expr(arr1).eq arr2
      expect(query._run()).toBe true

    it "supports nested queries", ->
      obj1 = { a: db.expr(2) }
      obj2 = { a: db.expr(1).add(1) }
      query = db.expr(obj1).eq obj2
      expect(query._run()).toBe true

  describe ".gt()", ->

    it "returns true if each value is greater than the next value", ->
      query = db.expr(1).gt 0, -1
      expect(query._run()).toBe true

    it "returns false if any value is not greater than the next value", ->
      query = db.expr(1).gt 0, 2
      expect(query._run()).toBe false

    # NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
    it "compares based on typeof (string > time > object > number > null > bool > array)", ->
      query = db.expr("").gt new Date, {}, 0, null, false, []
      expect(query._run()).toBe true

  describe ".lt()", ->

    it "returns true if each value is less than the next value", ->
      query = db.expr(0).lt 1, 2, 3
      expect(query._run()).toBe true

    it "returns false if any value is not less than the next value", ->
      query = db.expr(0).lt 1, 2, -3
      expect(query._run()).toBe false

    # NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
    it "compares based on typeof (array < bool < null < number < object < time < string)", ->
      query = db.expr([]).lt true, null, 1, {}, new Date, ""
      expect(query._run()).toBe true

  describe ".or()", ->

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

  describe ".and()", ->

    it "returns the last value if all other values are not false or null", ->
      query = db.expr(1).and 2, 3
      expect(query._run()).toBe 3

    it "returns the first value that is false or null", ->

      query = db.expr(true).and false, true
      expect(query._run()).toBe false

      query = db.expr(1).and null, 2
      expect(query._run()).toBe null

  describe ".add()", ->

    it "computes a sum of numbers", ->
      query = db.expr(1).add 1, 1
      expect(query._run()).toBe 3

    it "concatenates strings", ->
      query = db.expr("a").add "b", "c"
      expect(query._run()).toBe 'abc'

    it "concatenates arrays", ->
      arr = [1]
      query = db.expr(arr).add [2], [3]
      result = query._run()
      expect(result).not.toBe arr
      expect(result).toEqual [1, 2, 3]

  describe ".pluck()", ->

    it "copies the specified keys from one object to a new object", ->
      input = {a: 1, b: 2, c: 3}
      query = db.expr(input).pluck "a", "b"
      output = query._run()
      expect(output).toEqual {a: 1, b: 2}
      expect(output).not.toBe input

    it "ignores undefined values", ->
      query = db.expr(a: 1).pluck "a", "b"
      expect(query._run()).toEqual {a: 1}

    it "supports nested arrays", ->
      query = db.expr(a: 1).pluck ["a"]
      expect(query._run()).toEqual {a: 1}

    # it "supports nested queries", ->

    describe "key mapping", ->

      it "uses an object to pluck keys", ->
        query = db.expr(a: 1).pluck {a: true, b: true}
        expect(query._run()).toEqual {a: 1}

      it "supports strings as values", ->
        input = {a: {x: 1, y: 1}, b: {z: 1}, c: 1}
        query = db.expr(input).pluck {a: "x", b: "x", c: "x"}
        expect(query._run()).toEqual {a: {x: 1}}

      it "supports objects as values", ->
        input = {a: {x: 1, y: 1}, b: {z: 1}, c: 1}
        query = db.expr(input).pluck {a: {x: true}, b: {x: true}, c: {x: true}}
        expect(query._run()).toEqual {a: {x: 1}}

      it "supports arrays as values", ->
        input = {a: {x: 1, y: 1}, b: {z: 1}, c: 1}
        query = db.expr(input).pluck {a: ["x"], b: ["x"], c: ["x"]}
        expect(query._run()).toEqual {a: {x: 1}}

  describe ".without()", ->

    it "copies the unspecified keys from one object to a new object", ->
      input = {a: 1, b: 2, c: 3}
      query = db.expr(input).without "a", "c"
      output = query._run()
      expect(output).toEqual {b: 2}
      expect(output).not.toBe input

    it "supports nested arrays", ->
      query = db.expr(a: 1, b: 2, c: 3).without ["a"], ["c"]
      expect(query._run()).toEqual {b: 2}

    # it "supports nested objects", ->

    # it "supports nested queries", ->

  describe ".merge()", ->

    it "creates a new object by merging all given objects from left to right", ->
      obj = {a: 0}
      query = db.expr(obj).merge {a: 1, b: 0}, {b: 1, c: 1}
      res = query._run()
      expect(res).not.toBe obj
      expect(res).toEqual {a: 1, b: 1, c: 1}

    it "merges recursively", ->
      query = db.expr(a: {b: {c: 1}}).merge {a: {b: {d: 2}, e: 3}}
      equal = utils.equals query._run(), {a: {b: {c: 1, d: 2}, e: 3}}
      expect(equal).toBe true

    it "does not merge arrays", ->
      query = db.expr(a: [1, 2]).merge {a: [3]}
      expect(query._run()).toEqual {a: [3]}

    it "clones merged arrays", ->
      array = [1]
      query = db.expr({}).merge {array}
      res = query._run()
      expect(res.array).toEqual array
      expect(res.array).not.toBe array

    it "overwrites the first argument if an input is not an object", ->

      query = db.expr({}).merge 1
      expect(query._run()).toBe 1

      query = db.expr({}).merge {a: 1}, ""
      expect(query._run()).toBe ""

      query = db.expr({}).merge [1]
      expect(query._run()).toEqual [1]

      # Another object is created if a non-object input is followed by an object.
      query = db.expr({}).merge {a: 1}, null, {b: 2}
      expect(query._run()).toEqual {b: 2}
