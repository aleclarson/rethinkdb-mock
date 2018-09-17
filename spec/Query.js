const rethinkdb = require('..')
const utils = require('../lib/utils')

const db = rethinkdb()
const users = db.table('users')

// Test methods that support primitive types.
describe('Query', function() {
  beforeAll(() => db.init({ users: [] }))

  describe('.default()', function() {
    it('replaces null values with the given value', function() {
      const query = db(null).default(1)
      expect(query._run()).toBe(1)
    })

    it('avoids "missing attribute" errors', function() {
      const query = db({})('key').default(1)
      expect(query._run()).toBe(1)
    })

    it('avoids "index out of bounds" errors', function() {
      const query = db([])(0).default(1)
      expect(query._run()).toBe(1)
    })

    it('avoids "null not an object" errors', function() {
      const query = db(null)('key').default(1)
      expect(query._run()).toBe(1)
    })

    it('avoids "null not a sequence" errors', function() {
      const query = db(null)(0).default(1)
      expect(query._run()).toBe(1)
    })

    it('does not avoid other errors', function() {
      const query = db(1)
        .add('')
        .default(1)
      expect(() => query._run()).toThrow()
    })

    it('uses the first default value in a series of `default` calls', function() {
      const query = db(null)
        .default(1)
        .default(2)
      expect(query._run()).toBe(1)
    })
  })

  // it 'can be used in a nested query', ->

  describe('.do()', function() {
    it('calls the function when the query is evaluated', function() {
      let calls = 0
      const query = db(1).do(res => db(++calls))
      expect(calls).toBe(0)
      expect(query._run()).toBe(1)
      expect(query._run()).toBe(2)
    })

    it('allows the function to have zero arguments', () =>
      expect(function() {
        const query = db(1).do(() => db(2))
        expect(query._run()).toBe(2)
      }).not.toThrow())

    it('throws if the function has the incorrect number of arguments', () =>
      expect(() => db.do(1, 2, a => a)).toThrowError(
        'Expected function with 2 arguments but found function with 1 argument'
      ))

    it('wraps primitive values returned by the function with `r.expr`', function() {
      const query = db(1).do(() => 0)
      expect(query._run()).toBe(0)
    })

    it('evaluates queries returned by the function', function() {
      const query = db(1).do(() => db(0).add(2))
      expect(query._run()).toBe(2)
    })

    it('clones selections passed as arguments to the function', function() {
      users.insert({ id: 1 })._run()
      const query = users(0).do(user => user.delete())
      expect(() => query._run()).toThrowError(
        'Expected type SELECTION but found DATUM'
      )
    })

    it('does not clone selections returned by the function', function() {
      const query = db(1).do(() => users(0))
      expect(query.delete()._run()).toEqual({ deleted: 1, skipped: 0 })
      expect(db._tables.users.length).toBe(0)
    })

    it('only runs its parent query once', function() {
      const query = users.insert({ id: 1 }).do(res =>
        res('inserted')
          .eq(1)
          .and(res('errors').eq(0))
      )
      expect(query._run()).toBe(true)
      expect(db._tables.users.length).toBe(1)
    })
  })

  describe('.equals()', function() {
    it('returns true if two values are equal', function() {
      const query = db(1).eq(1)
      expect(query._run()).toBe(true)
    })

    it('returns true if all values are equal', function() {
      const query = db(1).eq(1, 1)
      expect(query._run()).toBe(true)
    })

    it('returns false if any value is not equal', function() {
      const query = db(1).eq(1, 2, 1)
      expect(query._run()).toBe(false)
    })

    it('compares objects recursively', function() {
      const obj1 = { a: { b: { c: 1 } } }
      const obj2 = { a: { b: { c: 1 } } }
      const query = db(obj1).eq(obj2)
      expect(query._run()).toBe(true)
    })

    it('compares arrays recursively', function() {
      const arr1 = [1, [2, [3]]]
      const arr2 = [1, [2, [3]]]
      const query = db(arr1).eq(arr2)
      expect(query._run()).toBe(true)
    })

    it('supports nested queries', function() {
      const obj1 = { a: db(2) }
      const obj2 = { a: db(1).add(1) }
      const query = db(obj1).eq(obj2)
      expect(query._run()).toBe(true)
    })
  })

  describe('.gt()', function() {
    it('returns true if each value is greater than the next value', function() {
      const query = db(1).gt(0, -1)
      expect(query._run()).toBe(true)
    })

    it('returns false if any value is not greater than the next value', function() {
      const query = db(1).gt(0, 2)
      expect(query._run()).toBe(false)
    })

    // NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
    it('compares based on typeof (string > time > object > number > null > bool > array)', function() {
      const query = db('').gt(new Date(), {}, 0, null, false, [])
      expect(query._run()).toBe(true)
    })
  })

  describe('.lt()', function() {
    it('returns true if each value is less than the next value', function() {
      const query = db(0).lt(1, 2, 3)
      expect(query._run()).toBe(true)
    })

    it('returns false if any value is not less than the next value', function() {
      const query = db(0).lt(1, 2, -3)
      expect(query._run()).toBe(false)
    })

    // NOTE: Time is less than string, because `typeOf` returns PTYPE<TIME>
    it('compares based on typeof (array < bool < null < number < object < time < string)', function() {
      const query = db([]).lt(true, null, 1, {}, new Date(), '')
      expect(query._run()).toBe(true)
    })
  })

  describe('.or()', function() {
    it('returns the last value if all other values are false or null', function() {
      let query = db(false).or(null, false)
      expect(query._run()).toBe(false)

      query = db(false).or(false, null)
      expect(query._run()).toBe(null)
    })

    it('returns the first value that is not false or null', function() {
      let query = db(false).or(null, 1, 2)
      expect(query._run()).toBe(1)

      query = db(null).or(true, 1)
      expect(query._run()).toBe(true)
    })
  })

  describe('.and()', function() {
    it('returns the last value if all other values are not false or null', function() {
      const query = db(1).and(2, 3)
      expect(query._run()).toBe(3)
    })

    it('returns the first value that is false or null', function() {
      let query = db(true).and(false, true)
      expect(query._run()).toBe(false)

      query = db(1).and(null, 2)
      expect(query._run()).toBe(null)
    })
  })

  describe('.add()', function() {
    it('computes a sum of numbers', function() {
      const query = db(1).add(1, 1)
      expect(query._run()).toBe(3)
    })

    it('concatenates strings', function() {
      const query = db('a').add('b', 'c')
      expect(query._run()).toBe('abc')
    })

    it('concatenates arrays', function() {
      const arr = [1]
      const query = db(arr).add([2], [3])
      const result = query._run()
      expect(result).not.toBe(arr)
      expect(result).toEqual([1, 2, 3])
    })
  })

  describe('.pluck()', function() {
    it('copies the specified keys from one object to a new object', function() {
      const input = { a: 1, b: 2, c: 3 }
      const query = db(input).pluck('a', 'b')
      const output = query._run()
      expect(output).toEqual({ a: 1, b: 2 })
      expect(output).not.toBe(input)
    })

    it('ignores undefined values', function() {
      const query = db({ a: 1 }).pluck('a', 'b')
      expect(query._run()).toEqual({ a: 1 })
    })

    it('supports nested arrays', function() {
      const query = db({ a: 1 }).pluck(['a'])
      expect(query._run()).toEqual({ a: 1 })
    })

    // it 'supports nested queries', ->

    describe('key mapping', function() {
      it('uses an object to pluck keys', function() {
        const query = db({ a: 1 }).pluck({ a: true, b: true })
        expect(query._run()).toEqual({ a: 1 })
      })

      it('supports strings as values', function() {
        const input = { a: { x: 1, y: 1 }, b: { z: 1 }, c: 1 }
        const query = db(input).pluck({ a: 'x', b: 'x', c: 'x' })
        expect(query._run()).toEqual({ a: { x: 1 } })
      })

      it('supports objects as values', function() {
        const input = { a: { x: 1, y: 1 }, b: { z: 1 }, c: 1 }
        const query = db(input).pluck({
          a: { x: true },
          b: { x: true },
          c: { x: true },
        })
        expect(query._run()).toEqual({ a: { x: 1 } })
      })

      it('supports arrays as values', function() {
        const input = { a: { x: 1, y: 1 }, b: { z: 1 }, c: 1 }
        const query = db(input).pluck({ a: ['x'], b: ['x'], c: ['x'] })
        expect(query._run()).toEqual({ a: { x: 1 } })
      })
    })
  })

  describe('.without()', function() {
    it('copies the unspecified keys from one object to a new object', function() {
      const input = { a: 1, b: 2, c: 3 }
      const query = db(input).without('a', 'c')
      const output = query._run()
      expect(output).toEqual({ b: 2 })
      expect(output).not.toBe(input)
    })

    it('supports nested arrays', function() {
      const query = db({ a: 1, b: 2, c: 3 }).without(['a'], ['c'])
      expect(query._run()).toEqual({ b: 2 })
    })
  })

  // it 'supports nested objects', ->

  // it 'supports nested queries', ->

  describe('.merge()', function() {
    it('creates a new object by merging all given objects from left to right', function() {
      const obj = { a: 0 }
      const query = db(obj).merge({ a: 1, b: 0 }, { b: 1, c: 1 })
      const res = query._run()
      expect(res).not.toBe(obj)
      expect(res).toEqual({ a: 1, b: 1, c: 1 })
    })

    it('merges recursively', function() {
      const query = db({ a: { b: { c: 1 } } }).merge({
        a: { b: { d: 2 }, e: 3 },
      })
      const equal = utils.equals(query._run(), {
        a: { b: { c: 1, d: 2 }, e: 3 },
      })
      expect(equal).toBe(true)
    })

    it('does not merge arrays', function() {
      const query = db({ a: [1, 2] }).merge({ a: [3] })
      expect(query._run()).toEqual({ a: [3] })
    })

    it('clones merged arrays', function() {
      const array = [1]
      const query = db({}).merge({ array })
      const res = query._run()
      expect(res.array).toEqual(array)
      expect(res.array).not.toBe(array)
    })

    it('overwrites the first argument if an input is not an object', function() {
      let query = db({}).merge(1)
      expect(query._run()).toBe(1)

      query = db({}).merge({ a: 1 }, '')
      expect(query._run()).toBe('')

      query = db({}).merge([1])
      expect(query._run()).toEqual([1])

      // Another object is created if a non-object input is followed by an object.
      query = db({}).merge({ a: 1 }, null, { b: 2 })
      expect(query._run()).toEqual({ b: 2 })
    })
  })
})
