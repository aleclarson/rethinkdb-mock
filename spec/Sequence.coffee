
rethinkdb = require ".."

db = rethinkdb()

users = db.table "users"

describe "sequence()", ->

  beforeAll ->
    db.init users: [
      {id: 1, name: "Betsy", gender: "F"}
      {id: 2, name: "Sheila", gender: "F", preference: "M"}
      {id: 3, name: "Alec", gender: "M", preference: "F"}
    ]

  it "can get a row by index", ->
    res = users(0)._run()
    expect(res).toEqual db._tables.users[0]

  it "can get a field from each row in the sequence", ->
    res = users("gender")._run()
    expect(res).toEqual ["F", "F", "M"]

# describe "sequence.do()", ->

describe "sequence.nth()", ->

  it "gets the nth row in the sequence", ->
    res = users.nth(1)._run()
    expect(res).not.toBe db._tables.users[1]
    expect(res.id).toBe 2

  it "throws for indexes less than -1", ->
    query = users.nth -2
    expect -> query._run()
    .toThrowError "Cannot use an index < -1 on a stream"

describe "sequence.getField()", ->

  it "gets a field from each row in the sequence", ->
    res = users.getField("gender")._run()
    expect(res).toEqual ["F", "F", "M"]

  it "ignores rows where the field is undefined", ->
    res = users.getField("preference")._run()
    expect(res).toEqual ["M", "F"]

describe "sequence.offsetsOf()", ->

  it "gets the index of every row matching the given value", ->
    user2 = users.nth index = 2
    res = users.offsetsOf(user2)._run()
    expect(Array.isArray res).toBe true
    expect(res.length).toBe 1
    expect(index).toBe res[0]

describe "sequence.update()", ->

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

describe "sequence.filter()", ->

  it "returns an array of rows matching the filter", ->
    query = users.filter {gender: "F"}
    res = query._run().map (row) -> row.name
    expect(res).toEqual ["Betsy", "Sheila"]

  # it "supports nested objects", ->

  # it "supports nested arrays", ->

  # it "supports nested queries", ->

describe "sequence.orderBy()", ->

  it "sorts the sequence using the given key", ->
    query = users.orderBy "name"
    res = query._run().map (row) -> row.name
    expect(res).toEqual ["Alec", "Betsy", "Sheila"]

  # it "can sort using a sub-query", ->

  # it "can sort in descending order", ->

describe "sequence.limit()", ->

  it "limits the number of results", ->
    query = users.limit 2
    res = query._run().map (row) -> row.id
    expect(res).toEqual [1, 2]

describe "sequence.slice()", ->

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

describe "sequence.pluck()", ->

  it "plucks keys from each result", ->
    query = users.pluck "name", "gender"
    res = query._run()
    expect(res.length).toBe db._tables.users.length
    res.forEach (user) ->
      expect(Object.keys user).toEqual ["name", "gender"]

describe "sequence.without()", ->

  it "excludes keys from each result", ->
    query = users.without "id", "age", "preference"
    res = query._run()
    expect(res.length).toBe db._tables.users.length
    res.forEach (user) ->
      expect(Object.keys user).toEqual ["name", "gender"]

describe "sequence.fold()", ->

describe "sequence.delete()", ->

  it "deletes every row in the sequence", ->
