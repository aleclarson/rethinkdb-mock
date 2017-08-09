
# rethinkdb-mock v0.4.0

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

1. Install from Github:

```sh
npm install --save-dev aleclarson/rethinkdb-mock#0.4.0
```

2. Put some boilerplate in your test environment:

```js
const rethinkdb = require('rethinkdb-mock')

// Replace `rethinkdbdash` with `rethinkdb-mock`
const mock = require('mock-require')
mock('rethinkdbdash', rethinkdb)

// You must use the same database name as the code you're testing.
const db = rethinkdb({
  name: 'test' // The default value
})
```

3. Use it in your test suites:

```js
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

- `r.table()`
- `r.do()`
- `r.expr()`
- `r.object()`
- `r.branch()`
- `r.desc()`
- `r.typeOf()`
- `r.uuid()`

- `table.get()`
- `table.getAll()`
- `table.insert()`
- `table.delete()`

- `query()`
- `query.bracket()`
- `query.nth()`
- `query.getField()`
- `query.hasFields()`
- `query.offsetsOf()`
- `query.count()`
- `query.limit()`
- `query.slice()`
- `query.filter()`
- `query.fold()`
- `query.merge()`
- `query.pluck()`
- `query.without()`
- `query.replace()`
- `query.update()`
- `query.delete()`
- `query.default()`
- `query.branch()`
- `query.do()`
- `query.eq()`
- `query.ne()`
- `query.gt()`
- `query.lt()`
- `query.ge()`
- `query.le()`
- `query.add()`
- `query.sub()`
- `query.mul()`
- `query.div()`
- `query.and()`
- `query.or()`

---

### What's missing?

This list may not be exhaustive and will be updated accordingly.

- `r.row`
- `r.args()`
- `r.tableCreate()`
- `r.tableList()`
- `r.tableDrop()`
- `r.indexCreate()`
- `r.indexList()`
- `r.indexDrop()`
- `r.indexRename()`
- `r.indexStatus()`
- `r.indexWait()`
- `r.range()`
- `r.error()`
- `r.js()`
- `r.json()`
- `r.http()`

- `query.info()`
- `query.sync()`
- `query.toJSON()`
- `query.between()`
- `query.forEach()`
- `query.coerceTo()`
- `query.innerJoin()`
- `query.outerJoin()`
- `query.eqJoin()`
- `query.zip()`
- `query.group()`
- `query.ungroup()`
- `query.reduce()`
- `query.distinct()`
- `query.contains()`
- `query.map()`
- `query.withFields()`
- `query.concatMap()`
- `query.skip()`
- `query.isEmpty()`
- `query.sample()`
- `query.setInsert()`
- `query.setUnion()`
- `query.setIntersection()`
- `query.setDifference()`
- `query.append()`
- `query.prepend()`
- `query.union()`
- `query.difference()`
- `query.insertAt()`
- `query.spliceAt()`
- `query.deleteAt()`
- `query.changeAt()`
- `query.keys()`
- `query.values()`
- `query.literal()`
- `query.match()`
- `query.split()`
- `query.upcase()`
- `query.downcase()`
- `query.sum()`
- `query.avg()`
- `query.min()`
- `query.max()`
- `query.mod()`
- `query.not()`
- `query.random()`
- `query.round()`
- `query.ceil()`
- `query.floor()`

- Administration methods
- Geospatial methods
- Date/time methods
- Binary support
- Changefeeds

---

### Similar repositories

- [JohanObrink/rethink-mock](https://github.com/JohanObrink/rethink-mock): Stubs for `sinon` (last updated August 2016)
- [vasc/rethinkdb-mock](https://github.com/vasc/rethinkdb-mock): Small subset of Rethink API, not spec-compliant (last updated April 2014)
