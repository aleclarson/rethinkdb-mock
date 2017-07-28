
isType = require "isType"

rethinkdb = require ".."

tables =
  users: []

db = rethinkdb {tables}

users = db.table "users"

describe "db.table().insert()", ->

  it "appends a row", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.inserted).toBe 1
      expect(tables.users.length).toBe 1

  it "throws for a duplicate primary key", ->
    users.insert {id: 1}
    .then (res) ->
      expect(res.errors).toBe 1
      expect(tables.users.length).toBe 1

  it "generates a UUID if no primary key is defined", ->
    users.insert {}
    .then (res) ->
      expect(res.inserted).toBe 1
      expect(isType res.generated_keys, Array).toBe yes
      expect(tables.users.length).toBe 2
      expect(tables.users[1].id).toBe res.generated_keys[0]

describe "db.table().get()", ->

  it "gets a row by its primary key", ->
    users.get 1
    .then (res) ->
      expect(res).toBe tables.users[0]
      expect(res.id).toBe 1

describe "db.table().getAll()", ->

  beforeAll ->
    users.insert {id: 2, friendCount: 5}

  it "gets matching rows", ->
    users.getAll 1, 2
    .then (res) ->
      expect(res.length).toBe 2

  it "can use secondary indexes", ->
    users.getAll 5, {index: "friendCount"}
    .then (res) ->
      expect(res.length).toBe 1

describe "db.table()", ->

  it "gets all rows", ->
    users.then (users) ->
      expect(users).not.toBe tables.users
      expect(users.length).toBe 3

describe "db.table().delete()", ->

  it "deletes all rows", ->
    users.delete()
    .then (res) ->
      expect(res.deleted).toBe 3
      expect(tables.users.length).toBe 0
