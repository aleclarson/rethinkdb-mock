var Database, assertType, cache, utils;

assertType = require("assertType");

Database = require("./Database");

utils = require("./utils");

cache = Object.create(null);

module.exports = function(options) {
  var db, name;
  if (options == null) {
    options = {};
  }
  assertType(options, Object);
  name = options.name || "test";
  if (db = cache[name]) {
    return db;
  }
  db = new Database(name);
  db.init = function(tables) {
    assertType(tables, Object);
    this._tables = tables;
  };
  cache[name] = db;
  return db;
};

utils.isQuery = utils.isQuery.bind(utils, [require("./Selection"), require("./Sequence"), require("./Datum"), require("./Table")]);
