
isType = require "isType"

rethinkdb = require ".."

db = rethinkdb()

db.init users: []

users = db.table "users"

describe "db.table().insert()", ->

  it "appends a row", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.inserted).toBe 1
      expect(db._tables.users.length).toBe 1

  it "throws for a duplicate primary key", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.errors).toBe 1
      expect(db._tables.users.length).toBe 1

  it "generates a UUID if no primary key is defined", ->
    users.insert {}
    .then (res) ->
      expect(res.inserted).toBe 1
      expect(isType res.generated_keys, Array).toBe true
      expect(db._tables.users.length).toBe 2
      expect(db._tables.users[1].id).toBe res.generated_keys[0]

describe "db.table().get()", ->

  it "gets a row by its primary key", ->
    users.get 1
    .then (res) ->
      expect(res).toBe db._tables.users[0]
      expect(res.id).toBe 1

  it "returns null if a row does not exist", ->
    users.get 100
    .then (res) ->
      expect(res).toBe null

describe "db.table().getAll()", ->

  beforeAll ->
    Promise.all [
      users.insert {id: 2, friendCount: 5}
      users.insert {id: 3, friendCount: 5}
    ]

  it "gets matching rows", ->
    users.getAll 1, 2
    .then (res) ->
      expect(res.length).toBe 2

  it "can use secondary indexes", ->
    users.getAll 5, {index: "friendCount"}
    .then (res) ->
      expect(res.length).toBe 2

describe "db.table()", ->

  it "gets every row in the table", ->
    users.then (users) ->
      expect(users).not.toBe db._tables.users
      expect(users.length).toBe db._tables.users.length

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
