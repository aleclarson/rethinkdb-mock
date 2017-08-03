
rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "selection.replace()", ->

  beforeAll ->
    db.init users: []
    users.insert {id: 1, name: "Alec"}

  it "replaces an entire row", ->
    query = users.get(1).replace {id: 1, name: "Shaggy"}
    expect(query._run()).toEqual {replaced: 1}

  it "knows if the row has not changed", ->
    query = users.get(1).replace {id: 1, name: "Shaggy"}
    expect(query._run()).toEqual {unchanged: 1}

  it "throws an error if no primary key is defined", ->
    query = users.get(1).replace {name: "Fred"}
    expect -> query._run()
    .toThrowError "Inserted object must have primary key `id`"

  it "throws an error if the primary key is different", ->
    query = users.get(1).replace {id: 2, name: "Nathan"}
    expect -> query._run()
    .toThrowError "Primary key `id` cannot be changed"

  it "deletes the row if the replacement is null", ->
    users.insert {id: 2, name: "Colin"}
    .then ->
      user2 = users.get 2

      query = user2.replace null
      expect(query._run()).toEqual {deleted: 1}
      expect(user2._run()).toBe null

      # Skip the replacement if no row exists.
      expect(query._run()).toEqual {skipped: 1}

describe "selection.update()", ->

  it "merges an object into an existing row", ->
    users.get(1).update {online: true}
    .then (res) ->
      expect(1).toBe res.replaced
      expect(true).toBe users.get(1)._run().online

  it "knows if the row has not changed", ->
    users.get(1).update {online: true}
    .then (res) ->
      expect(res.unchanged).toBe 1

  it "knows if the row does not exist", ->
    users.get(100).update {name: "Hulk Hogan"}
    .then (res) ->
      expect(res.skipped).toBe 1

  it "throws an error if the primary key is different", ->
    users.get(1).update {id: 2, name: "Jeff"}
    .run().catch (error) ->
      expect(error.message).toBe "Primary key `id` cannot be changed"

describe "selection.merge()", ->

  it "merges an object into the result (without updating the row)", ->
    user1 = users.get 1
    user1.merge {age: 23}
    .then (res) ->
      expect(res.age).toBe 23
      expect(user1._run().age).toBe undefined

describe "selection.delete()", ->

  it "deletes a row from its table", ->
    users.get(1).delete().then (res) ->
      expect(res.deleted).toBe 1
      expect(db._tables.users.length).toBe 0
      users.get(1).then (res) ->
        expect(res).toBe null
