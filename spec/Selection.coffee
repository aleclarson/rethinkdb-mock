
rethinkdb = require ".."

db = rethinkdb()

db.init users: []

users = db.table "users"

describe "selection.replace()", ->

  beforeAll ->
    users.insert {id: 1, name: "Alec"}

  it "replaces an entire row", ->
    users.get(1).replace {id: 1, name: "Shaggy"}
    .then (res) ->
      expect(res.replaced).toBe 1

  it "knows if the row has not changed", ->
    users.get(1).replace {id: 1, name: "Shaggy"}
    .then (res) ->
      expect(res.unchanged).toBe 1

  it "throws an error if no primary key is defined", ->
    users.get(1).replace {name: "Fred"}
    .run().catch (error) ->
      expect(error.message).toBe "Inserted object must have primary key `id`"

  it "throws an error if the primary key is different", ->
    users.get(1).replace {id: 2, name: "Nathan"}
    .run().catch (error) ->
      expect(error.message).toBe "Primary key `id` cannot be changed"

describe "selection.update()", ->

  it "merges an object into an existing row", ->
    users.get(1).update {online: true}
    .then (res) ->
      expect(res.replaced).toBe 1

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

describe "selection.delete()", ->

  it "deletes a row from its table", ->
    users.get(1).delete().then (res) ->
      expect(res.deleted).toBe 1
      expect(db._tables.users.length).toBe 0
      users.get(1).then (res) ->
        expect(res).toBe null
