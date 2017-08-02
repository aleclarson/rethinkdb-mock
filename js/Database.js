var Database, Datum, Table, assertType, createObject, isArray, isConstructor, methods, sliceArray, utils;

isConstructor = require("isConstructor");

assertType = require("assertType");

sliceArray = require("sliceArray");

Table = require("./Table");

Datum = require("./Datum");

utils = require("./utils");

isArray = Array.isArray;

Database = function(name) {
  assertType(name, String);
  this._name = name;
  this._tables = {};
  return this;
};

methods = Database.prototype;

methods.table = function(tableId) {
  return Table(this, tableId);
};

methods.tableCreate = function(tableId) {
  throw Error("Not implemented");
};

methods.tableDrop = function(tableId) {
  throw Error("Not implemented");
};

methods.expr = function(value) {
  return Datum({
    _db: this,
    _run: function() {
      return utils.resolve(value);
    }
  });
};

methods.uuid = require("./utils/uuid");

methods.object = function() {
  var args;
  args = sliceArray(arguments);
  if (args.length % 2) {
    throw Error("Expected an even number of arguments");
  }
  return Datum({
    _db: this,
    _run: function() {
      return createObject(args);
    }
  });
};

methods.desc = function(attr) {
  return ["desc", attr];
};

module.exports = Database;

createObject = function(args) {
  var index, key, object;
  object = {};
  index = 0;
  while (index < args.length) {
    key = utils.resolve(args[index]);
    assertType(key, String);
    if (args[index + 1] === void 0) {
      throw Error("Argument " + (index + 1) + " to object may not be `undefined`");
    }
    object[key] = utils.resolve(args[index + 1]);
    index += 2;
  }
  return object;
};
