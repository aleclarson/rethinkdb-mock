var DELETE, Datum, GET, GET_ALL, INSERT, Selection, Sequence, Table, assertType, clearTable, getRow, getRows, i, insertRows, isArray, isConstructor, methods, setType, sliceArray, utils, uuid;

isConstructor = require("isConstructor");

assertType = require("assertType");

sliceArray = require("sliceArray");

setType = require("setType");

Selection = require("./Selection");

Sequence = require("./Sequence");

Datum = require("./Datum");

utils = require("./utils");

uuid = require("./utils/uuid");

isArray = Array.isArray;

i = 1;

GET = i++;

GET_ALL = i++;

INSERT = i++;

DELETE = i++;

Table = function(db, tableId, action) {
  var self;
  self = function(key) {
    return Sequence(self)._access(key);
  };
  self._db = db;
  self._tableId = tableId;
  if (action) {
    self._action = action;
  }
  return setType(self, Table);
};

methods = Table.prototype;

methods.get = function(id) {
  var self;
  self = Table(this._db, this._tableId, [GET, id]);
  return Selection(self);
};

methods.getAll = function() {
  var self;
  self = Table(this._db, this._tableId, [GET_ALL, sliceArray(arguments)]);
  return Sequence(self);
};

methods.insert = function(value, options) {
  var self;
  self = Table(this._db, this._tableId, [INSERT, value, options]);
  return Datum(self);
};

methods["delete"] = function() {
  var self;
  self = Table(this._db, this._tableId, [DELETE]);
  return Datum(self);
};

(function() {
  var keys;
  keys = "do nth getField offsetsOf update filter orderBy limit slice pluck without fold".split(" ");
  return keys.forEach(function(key) {
    return methods[key] = function() {
      var self;
      self = Sequence(this);
      return self[key].apply(self, arguments);
    };
  });
})();

methods.run = function() {
  return Promise.resolve().then((function(_this) {
    return function() {
      if (_this._action) {
        return _this._run();
      }
      return utils.clone(_this._run());
    };
  })(this));
};

methods.then = function(onFulfilled) {
  return this.run().then(onFulfilled);
};

methods._run = function(context) {
  var action, table;
  if (!(table = this._db._tables[this._tableId])) {
    throw Error("Table `" + this._tableId + "` does not exist");
  }
  if (context != null) {
    context.tableId = this._tableId;
  }
  if (!(action = this._action)) {
    return table;
  }
  switch (action[0]) {
    case INSERT:
      return insertRows(table, action[1], action[2]);
    case DELETE:
      return clearTable(table);
    case GET:
      return getRow(table, action[1]);
    case GET_ALL:
      return getRows(table, action[1]);
  }
};

module.exports = Table;

insertRows = function(table, rows) {
  var errors, generated_keys, j, len, res, row;
  rows = utils.resolve(rows);
  if (!isArray(rows)) {
    rows = [rows];
  }
  errors = 0;
  generated_keys = [];
  for (j = 0, len = rows.length; j < len; j++) {
    row = rows[j];
    assertType(row, Object);
    if (row.hasOwnProperty("id")) {
      if (getRow(table, row.id)) {
        errors += 1;
      } else {
        table.push(row);
      }
    } else {
      generated_keys.push(row.id = uuid());
      table.push(row);
    }
  }
  res = errors > 0 ? {
    errors: errors,
    first_error: "Duplicate primary key `id`"
  } : {};
  res.inserted = rows.length - errors;
  if (generated_keys.length) {
    res.generated_keys = generated_keys;
  }
  return res;
};

clearTable = function(table) {
  var count;
  count = table.length;
  table.length = 0;
  return {
    deleted: count
  };
};

getRow = function(table, id) {
  var row;
  if (id === void 0) {
    throw Error("Argument 1 to get may not be `undefined`");
  }
  if (utils.isQuery(id)) {
    id = id._run();
  }
  if ((id === null) || isConstructor(id, Object)) {
    throw Error("Primary keys must be either a number, string, bool, pseudotype or array");
  }
  row = table.find(function(row) {
    return row.id === id;
  });
  return row || null;
};

getRows = function(table, args) {
  var arg, index, j, key, len;
  if (!args.length) {
    return [];
  }
  if (isConstructor(args[args.length - 1], Object)) {
    key = args.pop().index;
  }
  for (index = j = 0, len = args.length; j < len; index = ++j) {
    arg = args[index];
    if (arg === void 0) {
      throw Error("Argument " + index + " to getAll may not be `undefined`");
    }
    if (utils.isQuery(arg)) {
      args[index] = arg._run();
    }
    if (arg === null) {
      throw Error("Keys cannot be NULL");
    }
    if (isConstructor(arg, Object)) {
      throw Error((key === "id" ? "Primary" : "Secondary") + " keys must be either a number, string, bool, pseudotype or array");
    }
  }
  if (key == null) {
    key = "id";
  }
  return table.filter(function(row) {
    var k, len1;
    for (k = 0, len1 = args.length; k < len1; k++) {
      arg = args[k];
      if (isArray(arg)) {
        if (utils.equals(arg, row[key])) {
          return true;
        }
      } else if (arg === row[key]) {
        return true;
      }
    }
    return false;
  });
};
