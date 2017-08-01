var ACCESS, COUNT, DELETE, Datum, FILTER, FOLD, GET_FIELD, HAS_FIELDS, LIMIT, NTH, OFFSETS_OF, ORDER_BY, PLUCK, SLICE, Selection, Sequence, UPDATE, WITHOUT, assertType, deleteRows, i, methods, seq, setType, sliceArray, updateRows, utils;

assertType = require("assertType");

sliceArray = require("sliceArray");

setType = require("setType");

Selection = require("./Selection");

Datum = require("./Datum");

utils = require("./utils");

seq = require("./utils/seq");

i = 1;

NTH = i++;

ACCESS = i++;

GET_FIELD = i++;

HAS_FIELDS = i++;

OFFSETS_OF = i++;

ORDER_BY = i++;

FILTER = i++;

COUNT = i++;

LIMIT = i++;

SLICE = i++;

PLUCK = i++;

WITHOUT = i++;

FOLD = i++;

UPDATE = i++;

DELETE = i++;

Sequence = function(query, action) {
  var self;
  self = function(key) {
    return self._access(key);
  };
  self._db = query._db;
  self._query = query;
  if (action) {
    self._action = action;
  }
  return setType(self, Sequence);
};

methods = Sequence.prototype;

methods["do"] = function(callback) {
  return callback(this);
};

methods.nth = function(index) {
  var self;
  self = Sequence(this, [NTH, index]);
  return Selection(self);
};

methods.getField = function(attr) {
  return Sequence(this, [GET_FIELD, attr]);
};

methods.hasFields = function() {
  return Sequence(this, [HAS_FIELDS, sliceArray(arguments)]);
};

methods.offsetsOf = function(value) {
  var self;
  self = Sequence(this, [OFFSETS_OF, value]);
  return Datum(self);
};

methods.orderBy = function(value) {
  return Sequence(this, [ORDER_BY, value]);
};

methods.filter = function(filter, options) {
  return Sequence(this, [FILTER, filter, options]);
};

methods.count = function() {
  var self;
  self = Sequence(this, [COUNT]);
  return Datum(self);
};

methods.limit = function(n) {
  return Sequence(this, [LIMIT, n]);
};

methods.slice = function() {
  return Sequence(this, [SLICE, sliceArray(arguments)]);
};

methods.pluck = function() {
  return Sequence(this, [PLUCK, sliceArray(arguments)]);
};

methods.without = function() {
  return Sequence(this, [WITHOUT, sliceArray(arguments)]);
};

methods.fold = function(value, iterator) {
  var self;
  self = Sequence(this, [FOLD, value, iterator]);
  return Datum(self);
};

methods.update = function(value, options) {
  var self;
  self = Sequence(this, [UPDATE, value, options]);
  return Datum(self);
};

methods["delete"] = function() {
  var self;
  self = Sequence(this, [DELETE]);
  return Datum(self);
};

methods.run = function() {
  return Promise.resolve().then(this._run.bind(this));
};

methods.then = function(onFulfilled) {
  return this.run().then(onFulfilled);
};

methods._access = function(key) {
  var self;
  self = Sequence(this, [ACCESS, key]);
  return Datum(self);
};

methods._run = function(context) {
  var action, rows;
  if (context == null) {
    context = {};
  }
  Object.assign(context, this._context);
  rows = this._query._run(context);
  assertType(rows, Array);
  if (!(action = this._action)) {
    return rows;
  }
  switch (action[0]) {
    case NTH:
      return utils.nth(rows, action[1]);
    case ACCESS:
      return seq.access(rows, action[1]);
    case GET_FIELD:
      return seq.getField(rows, action[1]);
    case HAS_FIELDS:
      return seq.hasFields(rows, action[1]);
    case OFFSETS_OF:
      return seq.offsetsOf(rows, action[1]);
    case FILTER:
      return seq.filter(rows, action[1], action[2]);
    case ORDER_BY:
      return seq.sort(rows, action[1]);
    case COUNT:
      return rows.length;
    case LIMIT:
      return seq.limit(rows, action[1]);
    case SLICE:
      return seq.slice(rows, action[1]);
    case PLUCK:
      return seq.pluck(rows, action[1]);
    case WITHOUT:
      return seq.without(rows, action[1]);
    case UPDATE:
      return updateRows(rows, action[1], action[2]);
    case DELETE:
      return deleteRows(this._db, context.tableId, rows);
  }
};

module.exports = Sequence;

updateRows = function(rows, values, options) {
  var j, len, replaced, row;
  if (utils.isQuery(values)) {
    values = values._run();
    assertType(values, Object);
  } else {
    assertType(values, Object);
    values = utils.resolve(values);
  }
  if (utils.isQuery(options)) {
    options = options._run();
    assertType(options, Object);
  } else if (options != null) {
    assertType(options, Object);
    options = utils.resolve(options);
  } else {
    options = {};
  }
  replaced = 0;
  for (j = 0, len = rows.length; j < len; j++) {
    row = rows[j];
    if (utils.update(row, values)) {
      replaced += 1;
    }
  }
  return {
    replaced: replaced,
    unchanged: rows.length - replaced
  };
};

deleteRows = function(db, tableId, rows) {
  var deleted;
  assertType(tableId, String);
  deleted = 0;
  db._tables[tableId] = db._tables[tableId].filter(function(row) {
    if (~rows.indexOf(row)) {
      deleted += 1;
      return false;
    }
    return true;
  });
  return {
    deleted: deleted
  };
};
