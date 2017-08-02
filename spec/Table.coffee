
rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "db.table().insert()", ->

  beforeAll ->
    db.init users: []

  it "appends a row", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.inserted).toBe 1
      expect(db._tables.users.length).toBe 1

  it "clones the row before inserting it", ->
    users.insert row = {id: 2}
    .then ->
      user = db._tables.users[1]
      expect(row).not.toBe user
      expect(row.id).toBe user.id

  it "throws for a duplicate primary key", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.errors).toBe 1
      expect(db._tables.users.length).toBe 2

  it "generates a UUID if no primary key is defined", ->
    users.insert {}
    .then (res) ->
      key = res.generated_keys[0]
      expect(key).toBe users.get(key)._run().id
      expect(res.inserted).toBe 1

  it "can insert multiple rows at once", ->
    users.insert [{name: "Joe"}, {name: "Jim"}]
    .then (res) ->
      expect(res.inserted).toBe 2
      expect(res.generated_keys.length).toBe 2

  it "still inserts a row if other rows have duplicate primary keys", ->
    users.insert [{id: 2}, {id: 3}, {id: 1}]
    .then (res) ->
      expect(res.errors).toBe 2
      expect(res.inserted).toBe 1

describe "db.table().get()", ->

  it "gets a row by its primary key", ->
    users.get 1
    .then (user) ->
      expect(user.id).toBe 1

  it "clones the row before returning it", ->
    users.get 1
    .then (user) ->
      expect(user).not.toBe users.get(1)._run()

  it "returns null if a row never existed", ->
    users.get 100
    .then (user) ->
      expect(user).toBe null

  # it "supports sub-queries", ->

describe "db.table().getAll()", ->

  beforeAll ->
    Promise.all [
      users.get(2).update {friendCount: 5}
      users.get(3).update {friendCount: 5}
    ]

  it "gets matching rows", ->
    users.getAll 1, 2
    .then (users) ->
      expect(users.length).toBe 2

  it "can use secondary indexes", ->
    users.getAll 5, {index: "friendCount"}
    .then (users) ->
      expect(users.length).toBe 2

  # it "supports sub-queries", ->

  # it "can match an array", ->

describe "db.table()", ->

  it "gets every row in the table", ->
    users.then (results) ->
      expect(results).not.toBe db._tables.users
      expect(results.length).toBe db._tables.users.length

  it "clones each row before returning the results", ->
    users.then (results) ->
      for result, index in results
        expect(result).not.toBe db._tables.users[index]
      return

  it "throws if the table does not exist", ->
    db.table('animals').run().catch (error) ->
      expect(error.message).toBe "Table `animals` does not exist"

describe "db.table().delete()", ->

  it "deletes every row in the table", ->
    rowCount = db._tables.users.length
    users.delete()
    .then (res) ->
      expect(res.deleted).toBe rowCount
      expect(db._tables.users.length).toBe 0
