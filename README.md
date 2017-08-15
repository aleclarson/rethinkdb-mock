
# rethinkdb-mock v0.6.0

An in-memory RethinkDB used for testing.

The **end goal** is to replicate the API of [`rethinkdbdash`](https://github.com/neumino/rethinkdbdash).<br/>
For all intents and purposes, you should get the same results.<br/>
Please review the **Feature support** table before opening an issue.

Reusing and nesting queries are fully supported. :+1:

Check out the **Releases** tab for details about the newest versions.

---

### Why use this?

- Load JSON data into the database with `db.load()`
- Or call `db.init()` to easily populate the database
- Easily run specific tests (`fit` in Jasmine)
- Avoid teardown between test suites
- Avoid having to start a `rethinkdb` process before you can run tests
- Avoid mutilating your development `rethinkdb_data`
- Continuous integration compatibility

---

### Getting started

1. Install from Github:

```sh
npm install --save-dev rethinkdb-mock
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

    // Optionally, load JSON into the database.
    db.load(__dirname, './data.json')
  })

  // Now create your tests...
})
```

---

### Feature support

The entire Rethink API is not yet implemented.<br/>
Get an idea of what's supported by referencing the table below.

**Open an issue to request a feature be implemented.**<br/>
But try implementing it yourself if you have time! :+1:

If a method is not behaving as expected, **please open an issue!**<br/>
But first check out `TODO.md` for a list of missing behaviors.

> ❌ means "not implemented yet"
>
> ⚠️ means "partially implemented"
>
> 💯 means "fully implemented"

% | Feature
--- | ---
❌ | Changefeeds
❌ | Binary support
❌ | Date-time support
❌ | Geospatial support
💯 | `r.table()`
💯 | `r.tableCreate()`
❌ | `r.tableList()`
💯 | `r.tableDrop()`
❌ | `r.indexCreate()`
❌ | `r.indexList()`
❌ | `r.indexDrop()`
❌ | `r.indexRename()`
❌ | `r.indexStatus()`
❌ | `r.indexWait()`
⚠️ | `r.row`
💯 | `r()` or `r.expr()`
💯 | `r.do()`
❌ | `r.args()`
💯 | `r.object()`
💯 | `r.branch()`
⚠️ | `r.typeOf()`
💯 | `r.uuid()`
⚠️ | `r.desc()`
⚠️ | `r.asc()`
❌ | `r.js()`
❌ | `r.json()`
❌ | `r.http()`
❌ | `r.error()`
❌ | `r.range()`
💯 | `table.get()`
💯 | `table.getAll()`
⚠️ | `table.insert()`
💯 | `table.delete()`
💯 | `query()` or `query.bracket()`
💯 | `query.nth()`
💯 | `query.getField()`
⚠️ | `query.hasFields()`
❌ | `query.withFields()`
⚠️ | `query.offsetsOf()`
⚠️ | `query.contains()`
⚠️ | `query.orderBy()`
💯 | `query.isEmpty()`
💯 | `query.count()`
💯 | `query.skip()`
💯 | `query.limit()`
💯 | `query.slice()`
❌ | `query.between()`
💯 | `query.merge()`
💯 | `query.pluck()`
⚠️ | `query.without()`
⚠️ | `query.replace()`
⚠️ | `query.update()`
⚠️ | `query.delete()`
💯 | `query.default()`
💯 | `query.and()`
💯 | `query.or()`
⚠️ | `query.eq()`
⚠️ | `query.ne()`
⚠️ | `query.gt()`
⚠️ | `query.lt()`
⚠️ | `query.ge()`
⚠️ | `query.le()`
⚠️ | `query.add()`
⚠️ | `query.sub()`
⚠️ | `query.mul()`
💯 | `query.div()`
❌ | `query.mod()`
❌ | `query.sum()`
❌ | `query.avg()`
❌ | `query.min()`
❌ | `query.max()`
❌ | `query.not()`
❌ | `query.ceil()`
❌ | `query.floor()`
❌ | `query.round()`
❌ | `query.random()`
❌ | `query.coerceTo()`
💯 | `query.map()`
⚠️ | `query.filter()`
❌ | `query.fold()`
❌ | `query.reduce()`
❌ | `query.forEach()`
❌ | `query.distinct()`
❌ | `query.concatMap()`
❌ | `query.innerJoin()`
❌ | `query.outerJoin()`
❌ | `query.eqJoin()`
❌ | `query.zip()`
❌ | `query.group()`
❌ | `query.ungroup()`
❌ | `query.sample()`
❌ | `query.setInsert()`
❌ | `query.setUnion()`
❌ | `query.setIntersection()`
❌ | `query.setDifference()`
❌ | `query.append()`
❌ | `query.prepend()`
❌ | `query.union()`
❌ | `query.difference()`
❌ | `query.insertAt()`
❌ | `query.spliceAt()`
❌ | `query.deleteAt()`
❌ | `query.changeAt()`
❌ | `query.keys()`
❌ | `query.values()`
❌ | `query.literal()`
❌ | `query.match()`
❌ | `query.split()`
❌ | `query.upcase()`
❌ | `query.downcase()`
❌ | `query.toJSON()` or `query.toJsonString()`
❌ | `query.info()`
❌ | `query.sync()`

---

### Contribution

Any contribution goes a long way for making this library more reliable.

Issues and pull requests are always appreciated! :grin:

The implementation is relatively simple, but if you have any questions, feel free to open an issue.

You can help expose edge cases by writing tests!

#### Getting started

```sh
# This tool compiles the `src` directory during `npm install`.
npm install -g coffee-build

# You can include `-b unstable` for the latest changes.
git clone https://github.com/aleclarson/rethinkdb-mock

# Install dependencies.
npm install

# Manually compile the `src` directory after you make any changes.
coffee -cb -o js src
```

---

### Similar repositories

- [JohanObrink/rethink-mock](https://github.com/JohanObrink/rethink-mock): Stubs for `sinon` (last updated August 2016)
- [vasc/rethinkdb-mock](https://github.com/vasc/rethinkdb-mock): Small subset of Rethink API, not spec-compliant (last updated April 2014)
