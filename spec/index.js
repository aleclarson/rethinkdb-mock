const rethinkdb = require('..')

const db = rethinkdb()
const users = db.table('users')

describe('Database', function() {
  beforeAll(() =>
    db.init({
      users: [{ id: 1, name: 'Alec' }],
    }))

  describe('()', () =>
    it('is shorthand for db.expr()', () => expect(1).toBe(db(1)._run())))

  describe('.expr()', function() {
    it('converts a literal into a query', () =>
      expect(1).toBe(db.expr(1)._run()))

    it('throws if the value is undefined', () =>
      expect(() => db.expr(undefined)).toThrowError(
        'Cannot convert `undefined` with r.expr()'
      ))

    it('throws if the value is an imaginary number', function() {
      expect(() => db.expr(NaN)).toThrowError('Cannot convert `NaN` to JSON')

      expect(() => db.expr(Infinity)).toThrowError(
        'Cannot convert `Infinity` to JSON'
      )

      expect(() => db.expr(-Infinity)).toThrowError(
        'Cannot convert `-Infinity` to JSON'
      )
    })

    it('clones objects', function() {
      const data = { a: 1 }
      const query = db.expr(data)
      const res = query._run()
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('clones objects nested in objects', function() {
      const data = { a: 1 }
      const query = db.expr({ data })
      const res = query._run().data
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('clones objects nested in arrays', function() {
      const data = { a: 1 }
      const query = db.expr([data])
      const res = query._run()[0]
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('clones arrays', function() {
      const data = [1, 2]
      const query = db.expr(data)
      const res = query._run()
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('clones arrays nested in objects', function() {
      const data = [1, 2]
      const query = db.expr({ data })
      const res = query._run().data
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('clones arrays nested in arrays', function() {
      const data = [1, 2]
      const query = db.expr([data])
      const res = query._run()[0]
      expect(res).toEqual(data)
      expect(res).not.toBe(data)
    })

    it('supports nested queries', function() {
      users.insert([{ id: 1, name: 'Alec' }, { id: 2, name: 'Marie' }])._run()
      const query = db.expr([users.get(1), users.get(2)])
      expect(query._run()).toEqual(db._tables.users)
    })
  })

  describe('.args()', function() {
    it('returns an array if not nested', function() {
      const args = db.args([1])
      expect(args._run()).toEqual([1])
    })

    it('is merged into the arguments of a query', function() {
      const args = db.args([1])
      const query = db(1).add(1, args, 1, args, 1)
      expect(query._run()).toBe(6)
    })

    it('can be nested in other `r.args` queries', function() {
      const args = db.args([1])
      const query = db(1).add(db.args([1, args, 1]))
      expect(query._run()).toBe(4)
    })

    // NOTE: This is not yet supported.
    xit('can be used to pass arguments to a chained query', function() {
      const args = db.args([{ a: 1 }, { b: 1 }])
      const query = args.merge({ c: 1 })
      expect(query._run()).toEqual({ a: 1, b: 1, c: 1 })
    })
  })

  describe('.object()', function() {
    it('creates an object from key-value pairs', function() {
      const query = db.object('a', 1, 'b', 2)
      expect(query._run()).toEqual({ a: 1, b: 2 })
    })

    it('throws if a key is not a string', function() {
      const query = db.object('a', 1, null, 2)
      expect(() => query._run()).toThrowError(
        'Expected type STRING but found NULL'
      )
    })

    it('throws if a key has no value', () =>
      expect(() => db.object('a', 1, 'b')).toThrowError(
        'Expected an even number of arguments'
      ))
  })

  // it 'supports nested queries', ->

  describe('.typeOf()', function() {
    it('returns NULL for null literals', function() {
      const query = db.typeOf(null)
      expect(query._run()).toBe('NULL')
    })

    it('returns BOOL for boolean literals', function() {
      const query = db.typeOf(true)
      expect(query._run()).toBe('BOOL')
    })

    it('returns STRING for string literals', function() {
      const query = db.typeOf('')
      expect(query._run()).toBe('STRING')
    })

    it('returns NUMBER for number literals', function() {
      const query = db.typeOf(0)
      expect(query._run()).toBe('NUMBER')
    })

    it('returns ARRAY for array literals', function() {
      const query = db.typeOf([])
      expect(query._run()).toBe('ARRAY')
    })

    it('returns OBJECT for object literals', function() {
      const query = db.typeOf({})
      expect(query._run()).toBe('OBJECT')
    })
  })

  describe('.table()', function() {
    it('gets every row in the table', function() {
      const res = users._run()
      expect(res).toEqual(db._tables.users)
      expect(res).not.toBe(db._tables.users)
    })

    it('clones each row before returning the results', function() {
      users._run().forEach((res, i) => {
        expect(res).toEqual(db._tables.users[i])
        expect(res).not.toBe(db._tables.users[i])
      })
    })

    it('throws if the table does not exist', function() {
      const query = db.table('animals')
      expect(() => query._run()).toThrowError('Table `animals` does not exist')
    })
  })
})
