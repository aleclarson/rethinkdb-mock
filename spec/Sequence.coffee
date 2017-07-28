
rethinkdb = require ".."
utils = require "../js/utils"

db = rethinkdb()

db.init users: []

users = db.table "users"

describe "sequence()", ->

  beforeAll ->
    Promise.all [
      users.insert {id: 1, gender: "M"}
      users.insert {id: 2, gender: "F"}
      users.insert {id: 3, gender: "F"}
    ]

  it "can get a row by index", ->
    users(0).then (res) ->
      expect(res).toBe db._tables.users[0]

  it "can get a field from each row in the sequence", ->
    users("gender").then (res) ->
      expected = ["M", "F", "F"]
      expect(utils.arrayEquals(res, expected)).toBe true

describe "sequence.do()", ->

describe "sequence.nth()", ->

  it "gets the nth row in the sequence", ->
    users.nth(1).then (res) ->
      expect(res).toBe db._tables.users[1]

describe "sequence.getField()", ->

  it "gets a field from each row in the sequence", ->
    users.getField("gender").then (res) ->
      expected = ["M", "F", "F"]
      expect(utils.arrayEquals(res, expected)).toBe true

describe "sequence.offsetsOf()", ->

describe "sequence.update()", ->

  it "updates every row in the sequence", ->
    users.update {gender: "X"}
    .then (res) ->
      expect(res.replaced).toBe 3
      for user in db._tables.users
        expect(user.gender).toBe "X"
      return

  # TODO: Test updating with nested queries.
  # it "works with nested queries", ->

  # TODO: Test filter/update combo.
  # it "works after filtering", ->

describe "sequence.filter()", ->

describe "sequence.orderBy()", ->

describe "sequence.limit()", ->

describe "sequence.slice()", ->

describe "sequence.pluck()", ->

describe "sequence.without()", ->

describe "sequence.fold()", ->

describe "sequence.delete()", ->

  it "deletes every row in the sequence", ->
