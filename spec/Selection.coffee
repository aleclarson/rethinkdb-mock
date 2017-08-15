# TODO: Test `do` callback returning a selection/sequence/table

utils = require "../js/utils"

# Test queries on a selection from a table.
describe "Selection", ->

  beforeAll ->
    db.init users: [
      {id: 1, name: "Alec"}
      {id: 2, name: "John"}
    ]

  describe ".replace()", ->

    it "replaces an entire row", ->
      query = users.get(1).replace {id: 1, name: "Shaggy"}
      expect(query._run()).toEqual {errors: 0, replaced: 1, unchanged: 0}

    it "knows if the row has not changed", ->
      query = users.get(1).replace {id: 1, name: "Shaggy"}
      expect(query._run()).toEqual {errors: 0, replaced: 0, unchanged: 1}

    it "throws if a row was not returned by the parent query", ->
      query = db.expr(1).replace null
      expect -> query._run()
      .toThrowError "Expected type SELECTION but found DATUM"

    it "throws if no primary key is defined", ->
      query = users.get(1).replace {name: "Fred"}
      expect -> query._run()
      .toThrowError "Inserted object must have primary key `id`"

    it "returns an error if the primary key is different", ->
      query = users.get(1).replace {id: 2, name: "Nathan"}
      res = query._run()
      expect(res.errors).toBe 1
      expect(res.first_error).toBe "Primary key `id` cannot be changed"

    it "deletes the row if the replacement is null", ->
      users.insert {id: 2, name: "Colin"}
      .then ->
        user2 = users.get 2

        query = user2.replace null
        expect(query._run()).toEqual {deleted: 1, skipped: 0}
        expect(user2._run()).toBe null

        # Skip the replacement if no row exists.
        expect(query._run()).toEqual {deleted: 0, skipped: 1}

  describe ".update()", ->

    it "merges an object into an existing row", ->
      user1 = users.get 1
      query = user1.update {online: true}
      expect(1).toBe query._run().replaced
      expect(true).toBe user1._run().online

    it "knows if the row has not changed", ->
      query = users.get(1).update {online: true}
      expect(1).toBe query._run().unchanged

    it "knows if the row does not exist", ->
      query = users.get(100).update {name: "Hulk Hogan"}
      expect(1).toBe query._run().skipped

    it "throws if the primary key is different", ->
      query = users.get(1).update {id: 2, name: "Jeff"}
      expect -> query._run()
      .toThrowError "Primary key `id` cannot be changed"

    # NOTE: This is not yet supported.
    xit "supports `options.returnChanges`", ->
      query = users.get(1).update {name: "Fred"}, {returnChanges: true}
      res = query._run()
      expected = [{new_val: {id: 1, name: "Fred"}, old_val: {id: 1, name: "John"}}]
      expect(utils.equals res.changes, expected).toBe true

  describe ".merge()", ->

    it "merges an object into the result (without updating the row)", ->
      user1 = users.get 1
      query = user1.merge {age: 23}
      expect(23).toBe query._run().age
      expect(undefined).toBe user1._run().age

  describe ".delete()", ->

    it "deletes a row from its table", ->
      user1 = users.get 1
      query = user1.delete()
      expect(1).toBe query._run().deleted
      expect(null).toBe user1._run()

# Test queries on an array of selections from a table.
describe "Selection arrays", ->

  beforeAll ->
    db.init users: [
      {id: 1, name: "Betsy", gender: "F"}
      {id: 2, name: "Sheila", gender: "F", preference: "M"}
      {id: 3, name: "Alec", gender: "M", preference: "F"}
    ]

  describe "()", ->

    it "can get a row by index", ->
      res = users(0)._run()
      expect(res).toEqual db._tables.users[0]

    it "can get a field from each row in the sequence", ->
      res = users("gender")._run()
      expect(res).toEqual ["F", "F", "M"]

  # describe ".do()", ->
  #
  #   it "converts selections into objects", ->

  describe ".nth()", ->

    it "gets the nth row in the sequence", ->
      res = users.nth(1)._run()
      expect(res).not.toBe db._tables.users[1]
      expect(res.id).toBe 2

    it "throws for indexes less than -1", ->
      query = users.nth -2
      expect -> query._run()
      .toThrowError "Cannot use an index < -1 on a stream"

  describe ".getField()", ->

    it "gets a field from each row in the sequence", ->
      res = users.getField("gender")._run()
      expect(res).toEqual ["F", "F", "M"]

    it "ignores rows where the field is undefined", ->
      res = users.getField("preference")._run()
      expect(res).toEqual ["M", "F"]

  describe ".offsetsOf()", ->

    it "gets the index of every row matching the given value", ->
      user2 = users.nth index = 2
      res = users.offsetsOf(user2)._run()
      expect(Array.isArray res).toBe true
      expect(res.length).toBe 1
      expect(index).toBe res[0]

  describe ".update()", ->

    it "updates every row in the sequence", ->
      query = users.update {age: 23}
      expect(query._run().replaced).toBe db._tables.users.length
      for user in db._tables.users
        expect(user.age).toBe 23
      return

    it "tracks how many rows were not updated", ->
      query = users.update {age: 23}
      expect(query._run().unchanged).toBe db._tables.users.length

    # TODO: Test updating with nested queries.
    # it "works with nested queries", ->

    # TODO: Test filter/update combo.
    # it "works after filtering", ->

  describe ".replace()", ->

    it "must use `r.row` to avoid errors", ->
      count = users.count()._run()
      query = users.replace db.row.without "preference"
      expect(query._run()).toEqual {errors: 0, replaced: count - 1, unchanged: 1}
      expect(users.hasFields("preference")._run()).toEqual []

    it "deletes every row when `null` is passed", ->
      db.init test: [{id: 1}, {id: 2}]
      query = db.table("test").replace null
      expect(query._run()).toEqual {deleted: 2}
      expect(db.table("test")._run()).toEqual []

  describe ".filter()", ->

    it "returns an array of rows matching the filter", ->
      query = users.filter {gender: "F"}
      res = query._run().map (row) -> row.name
      expect(res).toEqual ["Betsy", "Sheila"]

    # it "supports nested objects", ->

    # it "supports nested arrays", ->

    # it "supports nested queries", ->

  describe ".orderBy()", ->

    it "sorts the sequence using the given key", ->
      query = users.orderBy "name"
      res = query._run().map (row) -> row.name
      expect(res).toEqual ["Alec", "Betsy", "Sheila"]

    # it "can sort using a sub-query", ->

    # it "can sort in descending order", ->

  describe ".limit()", ->

    it "limits the number of results", ->
      query = users.limit 2
      res = query._run().map (row) -> row.id
      expect(res).toEqual [1, 2]

  describe ".slice()", ->

    it "returns a range of results", ->
      query = users.slice 1, 2
      res = query._run().map (row) -> row.id
      expect(res).toEqual [2]

    it "supports a closed right bound", ->
      query = users.slice 1, 2, {rightBound: "closed"}
      res = query._run().map (row) -> row.id
      expect(res).toEqual [2, 3]

    it "supports an open left bound", ->
      query = users.slice 0, 2, {leftBound: "open"}
      res = query._run().map (row) -> row.id
      expect(res).toEqual [2]

    it "ranges from the given index to the last index (when only one index is given)", ->
      query = users.slice 1
      res = query._run().map (row) -> row.id
      expect(res).toEqual [2, 3]

  describe ".pluck()", ->

    it "plucks keys from each result", ->
      query = users.pluck "name", "gender"
      res = query._run()
      expect(res.length).toBe db._tables.users.length
      res.forEach (user) ->
        expect(Object.keys user).toEqual ["name", "gender"]

  describe ".without()", ->

    it "excludes keys from each result", ->
      query = users.without "id", "age"
      res = query._run()
      expect(res.length).toBe db._tables.users.length
      res.forEach (user) ->
        expect(Object.keys user).toEqual ["name", "gender"]

  # describe ".delete()", ->
  #
  #   it "deletes every row in the sequence", ->
