
# rethinkdb-mock v0.1.0

An in-memory RethinkDB used for testing.

*Not all methods are implemented yet.*

The **end goal** is to replicate the API of [`rethinkdbdash`](https://github.com/neumino/rethinkdbdash).
You should get the same results with either library.
This goal won't be reached (anytime soon) without outside contribution.

It's pertinent this library is well-tested.
You can help expose edge cases by writing tests.

If you find a method not behaving as expected, please open an issue!

**Contributions are welcome!** :grin:

---

### Why use this?

Typically, when testing code that uses RethinkDB, you need to use the `rethinkdb` CLI to start a process
before running your tests. You'll decide to either connect to the same database you use for manual QA testing
or create a temporary database purely for automated testing (which you'll need to populate with data).

Using `rethinkdb-mock` allows you to create a database for each test suite, which means less
work goes into ensuring the database is in the expected state from one suite to the next.
And since test suites are typically split into their own files, the test order can force you to
perform confusing and unnecessary setup/teardown operations. It's often simpler to setup an
in-memory database dedicated to a specific test suite, especially if you only want to run
a specific suite with Jasmine's `fit`.

If this doesn't convince you, please open an issue explaining your reasoning! :+1:

---

### Getting started

```js
const rethinkdb = require('rethinkdb-mock')

// Replace `rethinkdbdash` with `rethinkdb-mock`
const mock = require('mock-require')
mock('rethinkdbdash', rethinkdb)

// You must use the same database name as the code you're testing.
const db = rethinkdb({
  name: 'test' // The default value
})

describe('Some test suite', () => {

  // Reset the database between suites.
  beforeAll(() => {
    db.init({
      users: [],
      friends: [],
    })
  })

  // Now create your tests...
})
```

---

### What's included?

Be advised that anything on this list may not support specific use cases yet.

**Please open an issue if you want a use case supported!** :+1:

- Reusing queries

- Nesting queries (most of the time)

- `Database` methods
  - `table`, `expr`, `object`, `desc`, `uuid`

- `Table` methods
  - `insert`, `get`, `getAll`, `delete`

- `Sequence` methods
  - `()`, `do`, `nth`, `getField`, `hasFields`, `offsetsOf`, `update`, `filter`, `orderBy`, `limit`, `slice`, `pluck`, `without`, `fold`, `delete`

- `Selection` methods
  - `()`, `do`, `eq`, `ne`, `merge`, `default`, `getField`, `hasFields`, `without`, `pluck`, `replace`, `update`, `delete`

- `Datum` methods
  - `()`, `do`, `eq`, `ne`, `gt`, `lt`, `ge`, `le`, `add`, `sub`, `merge`, `default`, `getField`, `hasFields`, `without`, `pluck`

---

### What's missing?

This list may not be exhaustive and will be updated accordingly.

- `r.row`

- Changefeeds

- Table creation, deletion, or indexing

- Writing data
  - `sync`

- Selecting data
  - `between`

- Joins
  - `innerJoin`, `outerJoin`, `eqJoin`, `zip`

- Aggregation
  - `group`, `ungroup`, `reduce`, `count`, `sum`, `avg`, `min`, `max`, `distinct`, `contains`

- Transformations
  - `map`, `withFields`, `concatMap`, `skip`, `isEmpty`, `union`, `sample`

- Set methods
  - `setInsert`, `setUnion`, `setIntersection`, `setDifference`

- Array methods
  - `append`, `prepend`, `difference`, `insertAt`, `spliceAt`, `deleteAt`, `changeAt`

- Object methods
  - `keys`, `values`, `literal`

- String manipulation
  - `match`, `split`, `upcase`, `downcase`

- Math methods
  - `mul`, `div`, `mod`, `and`, `or`, `not`, `random`, `round`, `ceil`, `floor`

- Control structures
  - `do`, `args`, `branch`, `binary`, `forEach`, `range`, `error`, `js`, `coerceTo`, `typeOf`, `info`, `json`, `toJSON`, `http`

- Date/time methods

- Geospatial commands

- Administration methods

---

### Similar repositories

- [JohanObrink/rethink-mock](https://github.com/JohanObrink/rethink-mock): Stubs for `sinon` (last updated August 2016)
- [vasc/rethinkdb-mock](https://github.com/vasc/rethinkdb-mock): Small subset of Rethink API, not spec-compliant (last updated April 2014)
