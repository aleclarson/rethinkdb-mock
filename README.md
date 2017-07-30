
# rethinkdb-mock v0.0.1

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

### What's included?

Be advised that anything on this list may not support specific use cases yet.

**Please open an issue if you want a use case supported!** :+1:

- Reusing queries

- Nesting queries (most of the time)

- `Database` methods
  - `table`, `object`, `desc`, `uuid`

- `Table` methods
  - `insert`, `get`, `getAll`, `delete`

- `Sequence` methods
  - `()`, `do`, `nth`, `getField`, `offsetsOf`, `update`, `filter`, `orderBy`, `limit`, `slice`, `pluck`, `without`, `fold`, `delete`

- `Selection` methods
  - `()`, `do`, `eq`, `ne`, `merge`, `default`, `getField`, `without`, `pluck`, `replace`, `update`, `delete`

- `Datum` methods
  - `()`, `do`, `eq`, `ne`, `gt`, `lt`, `ge`, `le`, `add`, `sub`, `merge`, `default`, `getField`, `without`, `pluck`

---

### What's missing?

This list may not be exhaustive and will be updated accordingly.

- `r.row`

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
  - `do`, `args`, `expr`, `branch`, `binary`, `forEach`, `range`, `error`, `js`, `coerceTo`, `typeOf`, `info`, `json`, `toJSON`, `http`

- Date/time methods

- Geospatial commands

- Administration methods

---

### Similar repositories

- [JohanObrink/rethink-mock](https://github.com/JohanObrink/rethink-mock): Stubs for `sinon` (last updated August 2016)
- [vasc/rethinkdb-mock](https://github.com/vasc/rethinkdb-mock): Small subset of Rethink API, not spec-compliant (last updated April 2014)
