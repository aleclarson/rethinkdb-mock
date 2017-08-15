var Query, Table, actions, assertType, define, isArray, isConstructor, methods, parseArgs, runQuery, setProto, sliceArray, utils;

isConstructor = require("isConstructor");

assertType = require("assertType");

sliceArray = require("sliceArray");

setProto = require("setProto");

actions = require("./actions");

Query = require("./Query");

utils = require("./utils");

isArray = Array.isArray;

parseArgs = Query.prototype._parseArgs;

runQuery = Query.prototype._run;

define = Object.defineProperty;

Table = function(db, tableId) {
  var query;
  query = function(key) {
    return query.bracket(key);
  };
  query._db = db;
  query._type = "TABLE";
  query._tableId = tableId;
  return setProto(query, Table.prototype);
};

methods = {};

methods["do"] = function(callback) {
  throw Error("Tables must be coerced to arrays before calling `do`");
};

"get getAll insert delete".split(" ").forEach(function(actionId) {
  var actionType, maxArgs;
  maxArgs = actions[actionId].arity[1];
  actionType = actions[actionId].type;
  return methods[actionId] = function() {
    var query;
    query = Table(this._db, this._tableId);
    query._actionId = actionId;
    if (maxArgs > 0) {
      query._args = arguments;
      parseArgs.call(query);
    }
    return Query(query, actionType);
  };
});

"nth bracket getField hasFields offsetsOf contains orderBy map filter\ncount limit slice merge pluck without update replace".split(/\r|\s/).forEach(function(actionId) {
  return methods[actionId] = function() {
    return Query(this, "TABLE")._then(actionId, arguments);
  };
});

methods.run = function() {
  return Promise.resolve().then(runQuery.bind(this));
};

methods.then = function(onFulfilled) {
  return this.run().then(onFulfilled);
};

methods._eval = function(ctx) {
  var args, table;
  if (!(table = this._db._tables[this._tableId])) {
    throw Error("Table `" + this._tableId + "` does not exist");
  }
  ctx.type = this._type;
  ctx.tableId = this._tableId;
  if (!this._actionId) {
    return table;
  }
  args = this._args;
  if (utils.isQuery(args)) {
    args = args._run();
    utils.assertArity(this._actionId, args);
  }
  return actions[this._actionId].call(ctx, table, args);
};

methods._run = runQuery;

utils.each(methods, function(method, key) {
  return define(Table.prototype, key, {
    value: method,
    writable: true
  });
});

module.exports = Table;
