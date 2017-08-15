var Database, Query, Table, assertType, define, isArray, methods, setProto, sliceArray, tableRE, utils;

assertType = require("assertType");

sliceArray = require("sliceArray");

setProto = require("setProto");

Table = require("./Table");

Query = require("./Query");

utils = require("./utils");

isArray = Array.isArray;

define = Object.defineProperty;

tableRE = /^[A-Z0-9_]+$/i;

Database = function(name) {
  var r;
  assertType(name, String);
  r = function(value) {
    return r.expr(value);
  };
  r._name = name;
  define(r, "_tables", {
    value: {},
    writable: true
  });
  return setProto(r, Database.prototype);
};

methods = {};

methods.init = function(tables) {
  var table, tableId;
  assertType(tables, Object);
  for (tableId in tables) {
    table = tables[tableId];
    if (!tableRE.test(tableId)) {
      throw Error("Table name `" + tableId + "` invalid (Use A-Za-z0-9_ only)");
    }
    assertType(table, Array);
    this._tables[tableId] = table;
  }
};

methods.load = function() {
  var filePath, json;
  filePath = require("path").resolve.apply(null, arguments);
  json = require("fs").readFileSync(filePath, "utf8");
  this._tables = JSON.parse(json);
};

methods.table = function(tableId) {
  if (tableId === void 0) {
    throw Error("Cannot convert `undefined` with r.expr()");
  }
  return Table(this, tableId);
};

methods.tableCreate = function(tableId) {
  assertType(tableId, String);
  if (!tableRE.test(tableId)) {
    throw Error("Table name `" + tableId + "` invalid (Use A-Za-z0-9_ only)");
  }
  if (this._tables.hasOwnProperty(tableId)) {
    throw Error("Table `" + (this._name + "." + tableId) + "` already exists");
  }
  this._tables[tableId] = [];
  return Query._expr({
    tables_created: 1
  });
};

methods.tableDrop = function(tableId) {
  assertType(tableId, String);
  if (!tableRE.test(tableId)) {
    throw Error("Table name `" + tableId + "` invalid (Use A-Za-z0-9_ only)");
  }
  if (delete this._tables[tableId]) {
    return Query._expr({
      tables_dropped: 1
    });
  }
  throw Error("Table `" + (this._name + "." + tableId) + "` does not exist");
};

methods.uuid = require("./utils/uuid");

methods.typeOf = function(value) {
  if (arguments.length !== 1) {
    throw Error("`typeOf` takes 1 argument, " + arguments.length + " provided");
  }
  return Query._expr(value).typeOf();
};

methods.branch = function(cond) {
  var args;
  args = sliceArray(arguments, 1);
  if (args.length < 2) {
    throw Error("`branch` takes at least 3 arguments, " + (args.length + 1) + " provided");
  }
  return Query._branch(Query._expr(cond), args);
};

methods["do"] = function(arg) {
  if (!arguments.length) {
    throw Error("`do` takes at least 1 argument, 0 provided");
  }
  return Query._do(Query._expr(arg), sliceArray(arguments, 1));
};

methods.expr = Query._expr;

methods.row = Query._row;

methods.args = function(args) {
  var query;
  if (utils.isQuery(args)) {
    throw Error("The first argument of `r.args` cannot be a query (yet)");
  }
  utils.expect(args, "ARRAY");
  args = args.map(function(arg) {
    if (utils.isQuery(arg) && arg._lazy) {
      throw Error("Implicit variable `r.row` cannot be used inside `r.args`");
    }
    return Query._expr(arg);
  });
  query = Query(null, "ARGS");
  query._eval = function(ctx) {
    var values;
    ctx.type = "DATUM";
    values = [];
    args.forEach(function(arg) {
      if (arg._type === "ARGS") {
        values = values.concat(arg._run());
        return;
      }
      values.push(arg._run());
    });
    return values;
  };
  return query;
};

methods.object = function() {
  var args, query;
  args = sliceArray(arguments);
  if (args.length % 2) {
    throw Error("Expected an even number of arguments");
  }
  args.forEach(function(arg, index) {
    if (arg === void 0) {
      throw Error("Argument " + index + " to object may not be `undefined`");
    }
  });
  query = Query(null, "DATUM");
  query._eval = function(ctx) {
    var index, key, result;
    result = {};
    index = 0;
    while (index < args.length) {
      key = utils.resolve(args[index]);
      utils.expect(key, "STRING");
      result[key] = utils.resolve(args[index + 1]);
      index += 2;
    }
    ctx.type = this._type;
    return result;
  };
  return query;
};

methods.asc = function(index) {
  return {
    ASC: true,
    index: index
  };
};

methods.desc = function(index) {
  return {
    DESC: true,
    index: index
  };
};

utils.each(methods, function(value, key) {
  return define(Database.prototype, key, {
    value: value
  });
});

module.exports = Database;
