
xdescribe "r.row", ->

  beforeAll ->
    db.init users: [
      {id: 1, name: "Alec", age: 23}
      {id: 2, name: "John", age: 40}
    ]

  it "works with `update`", ->
    query = users.get(1).update {age: db.row('age').add 1}
    expect(query._run()).toEqual {replaced: 1, skipped: 0}
    expect(users(0)('age')._run()).toBe 24

  xit "works with `map`", ->
    query = users.map db.row('name')
    expect(query._run()).toEqual ["Alec", "John"]

  xit "works with `filter`", ->
    query = users.filter db.row('name').match('^A')
    res = query._run()
    expected = [users(0)._run()]
    expect(utils.equals res, expected).toBe true

  it "works with arrays", ->
    array = [{x: 1}, {x: 2}]
    query = db(array).merge {y: db.row('x').add 1}
    res = query._run()
    expected = [{x: 1, y: 2}, {x: 2, y: 3}]
    expect(utils.equals res, expected).toBe true

  it "works with objects", ->
    query = db(x: 1).merge {y: db.row('x').add 1}
    expect(query._run()).toEqual {x: 1, y: 2}
