
isType = require "isType"

rethinkdb = require ".."
Datum = require "../js/Datum"

db = rethinkdb()

users = db.table "users"

describe "sequence()", ->

  beforeAll ->
    db.init users: []
    Promise.all [
      users.insert {id: 1, name: "Betsy", gender: "F"}
      users.insert {id: 2, name: "Sheila", gender: "F", preference: "M"}
      users.insert {id: 3, name: "Alec", gender: "M", preference: "F"}
    ]

  it "returns a Datum instance", ->
    expect(isType users(0), Datum).toBe true
    expect(isType users("gender"), Datum).toBe true

  it "can get a row by index", ->
    users(0).then (res) ->
      expect(res).toBe db._tables.users[0]

  it "can get a field from each row in the sequence", ->
    users("gender").then (res) ->
      expect(res).toEqual ["F", "F", "M"]

# describe "sequence.do()", ->

describe "sequence.nth()", ->

  it "gets the nth row in the sequence", ->
    users.nth(1).then (res) ->
      expect(res).not.toBe db._tables.users[1]
      expect(res.id).toBe 2

describe "sequence.getField()", ->

  it "gets a field from each row in the sequence", ->
    users.getField("gender").then (res) ->
      expect(res).toEqual ["F", "F", "M"]

  it "ignores rows where the field is undefined", ->
    users.getField("preference").then (res) ->
      expect(res).toEqual ["M", "F"]

describe "sequence.offsetsOf()", ->

  it "gets the index of every row matching the given value", ->
    index = 2
    users.nth(index).then (user) ->
      users.offsetsOf(user).then (res) ->
        expect(isType res, Array).toBe true
        expect(res.length).toBe 1
        expect(index).toBe res[0]

describe "sequence.update()", ->

  it "updates every row in the sequence", ->
    users.update {age: 23}
    .then (res) ->
      expect(res.replaced).toBe db._tables.users.length
      for user in db._tables.users
        expect(user.age).toBe 23
      return

  it "tracks how many rows were not updated", ->
    users.update {age: 23}
    .then (res) ->
      expect(res.unchanged).toBe db._tables.users.length

  # TODO: Test updating with nested queries.
  # it "works with nested queries", ->

  # TODO: Test filter/update combo.
  # it "works after filtering", ->

describe "sequence.filter()", ->

  it "returns an array of rows matching the filter", ->
    users.filter {gender: "F"}
    .then (res) ->
      res = res.map (row) -> row.name
      expect(res).toEqual ["Betsy", "Sheila"]

  # it "supports nested objects", ->

  # it "supports nested arrays", ->

  # it "supports nested queries", ->

describe "sequence.orderBy()", ->

  it "sorts the sequence using the given key", ->
    users.orderBy("name").then (res) ->
      res = res.map (row) -> row.name
      expect(res).toEqual ["Alec", "Betsy", "Sheila"]

  # it "can sort using a sub-query", ->

  # it "can sort in descending order", ->

describe "sequence.limit()", ->

  it "limits the number of results", ->
    users.limit(2).then (res) ->
      res = res.map (row) -> row.id
      expect(res).toEqual [1, 2]

describe "sequence.slice()", ->

  it "returns a range of results", ->
    users.slice(1, 2).then (res) ->
      res = res.map (row) -> row.id
      expect(res).toEqual [2]

  it "supports a closed right bound", ->
    users.slice(1, 2, {rightBound: "closed"}).then (res) ->
      res = res.map (row) -> row.id
      expect(res).toEqual [2, 3]

  it "supports an open left bound", ->
    users.slice(0, 2, {leftBound: "open"}).then (res) ->
      res = res.map (row) -> row.id
      expect(res).toEqual [2]

  it "ranges from the given index to the last index (when only one index is given)", ->
    users.slice(1).then (res) ->
      res = res.map (row) -> row.id
      expect(res).toEqual [2, 3]

describe "sequence.pluck()", ->

  it "plucks keys from each result", ->
    users.pluck "name", "gender"
    .then (users) ->
      expect(users.length).toBe db._tables.users.length
      for user in users
        expect(Object.keys user).toEqual ["name", "gender"]
      return

describe "sequence.without()", ->

  it "excludes keys from each result", ->
    users.without "id", "age", "preference"
    .then (users) ->
      expect(users.length).toBe db._tables.users.length
      for user in users
        expect(Object.keys user).toEqual ["name", "gender"]
      return

describe "sequence.fold()", ->

describe "sequence.delete()", ->

  it "deletes every row in the sequence", ->
