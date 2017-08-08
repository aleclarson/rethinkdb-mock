# TODO: Test `do` callback returning a selection/sequence/table

rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "selection.replace()", ->

  beforeAll ->
    db.init users: []
    users.insert {id: 1, name: "Alec"}

  it "replaces an entire row", ->
    query = users.get(1).replace {id: 1, name: "Shaggy"}
    expect(query._run()).toEqual {replaced: 1, unchanged: 0}

  it "knows if the row has not changed", ->
    query = users.get(1).replace {id: 1, name: "Shaggy"}
    expect(query._run()).toEqual {replaced: 0, unchanged: 1}

  it "throws if a row was not returned by the parent query", ->
    query = db.expr(1).replace null
    expect -> query._run()
    .toThrowError "Expected type SELECTION but found DATUM"

  it "throws if no primary key is defined", ->
    query = users.get(1).replace {name: "Fred"}
    expect -> query._run()
    .toThrowError "Inserted object must have primary key `id`"

  it "throws if the primary key is different", ->
    query = users.get(1).replace {id: 2, name: "Nathan"}
    expect -> query._run()
    .toThrowError "Primary key `id` cannot be changed"

  it "deletes the row if the replacement is null", ->
    users.insert {id: 2, name: "Colin"}
    .then ->
      user2 = users.get 2

      query = user2.replace null
      expect(query._run()).toEqual {deleted: 1, skipped: 0}
      expect(user2._run()).toBe null

      # Skip the replacement if no row exists.
      expect(query._run()).toEqual {deleted: 0, skipped: 1}

describe "selection.update()", ->

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

describe "selection.merge()", ->

  it "merges an object into the result (without updating the row)", ->
    user1 = users.get 1
    query = user1.merge {age: 23}
    expect(23).toBe query._run().age
    expect(undefined).toBe user1._run().age

describe "selection.delete()", ->

  it "deletes a row from its table", ->
    user1 = users.get 1
    query = user1.delete()
    expect(1).toBe query._run().deleted
    expect(null).toBe user1._run()
