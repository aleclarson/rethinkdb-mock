var ACCESS, ADD, COUNT, DELETE, DO, Datum, EQ, FILTER, GE, GET_FIELD, GT, HAS_FIELDS, LE, LIMIT, LT, MERGE, NE, NTH, OFFSETS_OF, ORDER_BY, PLUCK, REPLACE, SLICE, SUB, UPDATE, WITHOUT, assertType, i, isArray, merge, methods, setType, sliceArray, utils;

assertType = require("assertType");

sliceArray = require("sliceArray");

setType = require("setType");

utils = require("./utils");

isArray = Array.isArray;

i = 1;

DO = i++;

EQ = i++;

NE = i++;

GT = i++;

LT = i++;

GE = i++;

LE = i++;

ADD = i++;

SUB = i++;

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

MERGE = i++;

PLUCK = i++;

WITHOUT = i++;

REPLACE = i++;

UPDATE = i++;

DELETE = i++;

Datum = function(query, action) {
  var self;
  self = function(key) {
    return Datum(self, [ACCESS, key]);
  };
  self._db = query._db;
  self._query = query;
  if (action) {
    self._action = action;
  }
  return setType(self, Datum);
};

methods = Datum.prototype;

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
  return Datum(this, [EQ, value]);
};

methods.ne = function(value) {
  return Datum(this, [NE, value]);
};

methods.gt = function(value) {
  return Datum(this, [GT, value]);
};

methods.lt = function(value) {
  return Datum(this, [LT, value]);
};

methods.ge = function(value) {
  return Datum(this, [GE, value]);
};

methods.le = function(value) {
  return Datum(this, [LE, value]);
};

methods.add = function(value) {
  return Datum(this, [ADD, value]);
};

methods.sub = function(value) {
  return Datum(this, [SUB, value]);
};

methods.nth = function(value) {
  return Datum(this, [NTH, value]);
};

methods.getField = function(value) {
  return Datum(this, [GET_FIELD, value]);
};

methods.hasFields = function(value) {
  return Datum(this, [HAS_FIELDS, sliceArray(arguments)]);
};

methods.offsetsOf = function(value) {
  return Datum(this, [OFFSETS_OF, value]);
};

methods.orderBy = function(value) {
  return Datum(this, [ORDER_BY, value]);
};

methods.filter = function(filter, options) {
  return Datum(this, [FILTER, filter, options]);
};

methods.count = function() {
  return Datum(this, [COUNT]);
};

methods.limit = function(n) {
  return Datum(this, [LIMIT, n]);
};

methods.slice = function() {
  return Datum(this, [SLICE, sliceArray(arguments)]);
};

methods.merge = function() {
  return Datum(this, [MERGE, sliceArray(arguments)]);
};

methods.without = function() {
  return Datum(this, [WITHOUT, sliceArray(arguments)]);
};

methods.pluck = function() {
  return Datum(this, [PLUCK, sliceArray(arguments)]);
};

methods.replace = function(values) {
  return Datum(this, [REPLACE, values]);
};

methods.replace = function(values) {
  return Datum(this, [REPLACE, values]);
};

methods.update = function(values) {
  return Datum(this, [UPDATE, values]);
};

methods["delete"] = function() {
  return Datum(this, [DELETE]);
};

methods.run = function() {
  return Promise.resolve().then(this._run.bind(this));
};

methods.then = function(onFulfilled) {
  return this.run().then(onFulfilled);
};

methods._run = function(context) {
  var action, result;
  if (context == null) {
    context = {};
  }
  Object.assign(context, this._context);
  result = this._query._run(context);
  if (!(action = this._action)) {
    return result;
  }
  switch (action[0]) {
    case ACCESS:
      return utils.access(result, action[1]);
    case GET_FIELD:
      return utils.getField(result, action[1]);
    case HAS_FIELDS:
      return utils.hasFields(result, action[1]);
    case OFFSETS_OF:
      assertType(result, Array);
      return seq.offsetsOf(result, action[1]);
    case ORDER_BY:
      assertType(result, Array);
      return seq.sort(result, action[1]);
    case FILTER:
      assertType(result, Array);
      return seq.filter(result, action[1], action[2]);
    case COUNT:
      assertType(result, Array);
      return result.length;
    case LIMIT:
      assertType(result, Array);
      return seq.limit(result, action[1]);
    case SLICE:
      assertType(result, Array);
      return seq.slice(result, action[1]);
    case MERGE:
      return merge(result, action[1]);
    case WITHOUT:
      if (isArray(result)) {
        return seq.without(result, action[1]);
      }
      return utils.without(result, action[1]);
    case PLUCK:
      if (isArray(result)) {
        return seq.pluck(result, action[1]);
      }
      return utils.pluck(result, action[1]);
  }
};

module.exports = Datum;

merge = function(result, args) {
  if (isArray(result)) {
    return result.map(function(result) {
      assertType(result, Object);
      return utils.merge(utils.clone(result), args);
    });
  }
  assertType(result, Object);
  return utils.merge(utils.clone(result), args);
};
