var assertType, indexOf, row, utils;

assertType = require("assertType");

utils = require(".");

row = exports;

row.replace = function(db, tableId, rowId, values) {
  var index, table;
  if (values === void 0) {
    throw Error("Argument 1 to replace may not be `undefined`");
  }
  if (utils.isQuery(values)) {
    values = values._run();
    if (values !== null) {
      assertType(values, Object);
    }
  } else if (values !== null) {
    assertType(values, Object);
    values = utils.resolve(values);
  }
  table = db._tables[tableId];
  index = indexOf(table, rowId);
  if (values === null) {
    table.splice(index, 1);
    return {
      deleted: 1
    };
  }
  assertType(values, Object);
  if (!values.hasOwnProperty("id")) {
    throw Error("Inserted object must have primary key `id`");
  }
  if (values.id !== rowId) {
    throw Error("Primary key `id` cannot be changed");
  }
  if (utils.equals(table[index], values)) {
    return {
      unchanged: 1
    };
  }
  table[index] = values;
  return {
    replaced: 1
  };
};

row.update = function(row, values) {
  if (values === void 0) {
    throw Error("Argument 1 to update may not be `undefined`");
  }
  if (!row) {
    return {
      skipped: 1
    };
  }
  if (utils.isQuery(values)) {
    values = values._run();
    if (values !== null) {
      assertType(values, Object);
    }
  } else if (values !== null) {
    assertType(values, Object);
    values = utils.resolve(values);
  }
  if (values && utils.update(row, values)) {
    return {
      replaced: 1
    };
  }
  return {
    unchanged: 1
  };
};

row["delete"] = function(db, tableId, row) {
  var table;
  assertType(tableId, String);
  if (!row) {
    return {
      skipped: 1
    };
  }
  table = db._tables[tableId];
  table.splice(table.indexOf(row), 1);
  return {
    deleted: 1
  };
};

indexOf = function(table, rowId) {
  var index;
  index = -1;
  while (++index < table.length) {
    if (table[index].id === rowId) {
      return index;
    }
  }
  return -1;
};
