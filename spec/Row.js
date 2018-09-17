const rethinkdb = require('..')
const utils = require('../lib/utils')

const db = rethinkdb()
const users = db.table('users')

describe('r.row', function() {
  const user1 = users.get(1)

  beforeAll(() =>
    db.init({
      users: [
        { id: 1, name: 'Alec', age: 23 },
        { id: 2, name: 'John', age: 40 },
      ],
    }))

  it('works with `update`', function() {
    const query = user1.update({ age: db.row('age').add(1) })
    expect(query._run()).toEqual({ replaced: 1, unchanged: 0 })
    expect(user1('age')._run()).toBe(24)
  })

  it('works with `replace`', function() {
    user1.update({ foo: true })._run()
    const query = user1.replace(db.row.without('foo'))
    expect(query._run()).toEqual({ errors: 0, replaced: 1, unchanged: 0 })
    expect(user1.hasFields('foo')._run()).toBe(false)
  })

  it('works with `map`', function() {
    const query = users.map(db.row('name'))
    expect(query._run()).toEqual(['Alec', 'John'])
  })

  it('works with `filter`', function() {
    const query = users.filter(db.row('age').lt(30))
    expect(query._run()[0]).toEqual(user1._run())
  })

  it('works with `merge`', function() {
    // Test with an object...
    let query = db({ x: 1 }).merge({ y: db.row('x').add(1) })
    expect(query._run()).toEqual({ x: 1, y: 2 })

    // Test with arrays...
    const array = [{ x: 1 }, { x: 2 }]
    query = db(array).merge({ y: db.row('x').add(1) })
    const res = query._run()
    const expected = [{ x: 1, y: 2 }, { x: 2, y: 3 }]
    expect(utils.equals(res, expected)).toBe(true)
  })
})
