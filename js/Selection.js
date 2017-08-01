var DELETE, Datum, EQ, GET_FIELD, HAS_FIELDS, MERGE, NE, PLUCK, REPLACE, Selection, UPDATE, WITHOUT, assertType, i, methods, row, setType, sliceArray, utils;

assertType = require("assertType");

sliceArray = require("sliceArray");

setType = require("setType");

Selection = require("./Selection");

Datum = require("./Datum");

utils = require("./utils");

row = require("./utils/row");

i = 1;

EQ = i++;

NE = i++;

MERGE = i++;

GET_FIELD = i++;

HAS_FIELDS = i++;

WITHOUT = i++;

PLUCK = i++;

REPLACE = i++;

UPDATE = i++;

DELETE = i++;

Selection = function(query, action) {
  var self;
  self = function(attr) {
    return self._access(attr);
  };
  self._db = query._db;
  self._query = query;
  if (action) {
    self._action = action;
  }
  return setType(self, Selection);
};

methods = Selection.prototype;

methods["default"] = function(value) {
  var self;
  self = Datum(this);
  self._context = {
    "default": value
  };
  return self;
};

methods["do"] = function(callback) {
  return callback(this);
};

methods.eq = function(value) {
  var self;
  self = Selection(this._query, [EQ, value]);
  return Datum(self);
};

methods.ne = function(value) {
  var self;
  self = Selection(this._query, [NE, value]);
  return Datum(self);
};

methods.getField = function(attr) {
  var self;
  self = Selection(this._query, [GET_FIELD, attr]);
  return Datum(self);
};

methods.hasFields = function() {
  var self;
  self = Selection(this._query, [HAS_FIELDS, sliceArray(arguments)]);
  return Datum(self);
};

methods.merge = function() {
  var self;
  self = Selection(this._query, [MERGE, sliceArray(arguments)]);
  return Datum(self);
};

methods.without = function() {
  var self;
  self = Selection(this._query, [WITHOUT, sliceArray(arguments)]);
  return Datum(self);
};

methods.pluck = function() {
  var self;
  self = Selection(this._query, [PLUCK, sliceArray(arguments)]);
  return Datum(self);
};

methods.replace = function(values) {
  var self;
  self = Selection(this._query, [REPLACE, values]);
  return Datum(self);
};

methods.update = function(values) {
  var self;
  self = Selection(this._query, [UPDATE, values]);
  return Datum(self);
};

methods["delete"] = function() {
  var self;
  self = Selection(this._query, [DELETE]);
  return Datum(self);
};

methods.run = function() {
  return Promise.resolve().then(this._run.bind(this));
};

methods.then = function(onFulfilled) {
  return this.run().then(onFulfilled);
};

methods._access = function(attr) {
  var self;
  self = Selection(this._query, [GET_FIELD, attr]);
  return Datum(self);
};

methods._run = function(context) {
  var action, result;
  if (context == null) {
    context = {};
  }
  Object.assign(context, this._context);
  result = this._query._run(context);
  if (!(action = this._action)) {
    return utils.clone(result);
  }
  switch (action[0]) {
    case EQ:
      return utils.equals(result, action[1]);
    case NE:
      return !utils.equals(result, action[1]);
    case MERGE:
      return utils.merge(utils.clone(result), action[1]);
    case GET_FIELD:
      return utils.getField(result, action[1]);
    case HAS_FIELDS:
      return utils.hasFields(result, action[1]);
    case WITHOUT:
      return utils.without(result, action[1]);
    case PLUCK:
      return utils.pluck(result, action[1]);
    case REPLACE:
      return row.replace(this._db, context.tableId, result.id, action[1]);
    case UPDATE:
      return row.update(result, action[1]);
    case DELETE:
      return row["delete"](this._db, context.tableId, result);
  }
};

module.exports = Selection;
