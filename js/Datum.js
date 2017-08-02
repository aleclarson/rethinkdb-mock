var ACCESS, ADD, AND, COUNT, DELETE, DIV, DO, Datum, EQ, FILTER, GE, GET_FIELD, GT, HAS_FIELDS, LE, LIMIT, LT, MERGE, MUL, NE, NTH, OFFSETS_OF, OR, ORDER_BY, PLUCK, REPLACE, SLICE, SUB, UPDATE, WITHOUT, add, anyButFalse, assertType, divide, equals, greaterOrEqual, greaterThan, i, isArray, lessOrEqual, lessThan, merge, methods, multiply, noneFalse, row, setType, sliceArray, subtract, utils;

assertType = require("assertType");

sliceArray = require("sliceArray");

setType = require("setType");

utils = require("./utils");

row = require("./row");

isArray = Array.isArray;

i = 1;

DO = i++;

EQ = i++;

NE = i++;

GT = i++;

LT = i++;

GE = i++;

LE = i++;

OR = i++;

AND = i++;

ADD = i++;

SUB = i++;

MUL = i++;

DIV = i++;

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
  var query;
  query = this;
  return Datum({
    _db: this._db,
    _run: function() {
      var result;
      try {
        result = query._run();
      } catch (_error) {}
      return result != null ? result : value;
    }
  });
};

methods["do"] = function(callback) {
  return utils["do"](Datum(this), callback);
};

methods.eq = function() {
  return Datum(this, [EQ, sliceArray(arguments)]);
};

methods.ne = function() {
  return Datum(this, [NE, sliceArray(arguments)]);
};

methods.gt = function() {
  return Datum(this, [GT, sliceArray(arguments)]);
};

methods.lt = function() {
  return Datum(this, [LT, sliceArray(arguments)]);
};

methods.ge = function() {
  return Datum(this, [GE, sliceArray(arguments)]);
};

methods.le = function() {
  return Datum(this, [LE, sliceArray(arguments)]);
};

methods.or = function() {
  return Datum(this, [OR, sliceArray(arguments)]);
};

methods.and = function() {
  return Datum(this, [AND, sliceArray(arguments)]);
};

methods.add = function() {
  return Datum(this, [ADD, sliceArray(arguments)]);
};

methods.sub = function() {
  return Datum(this, [SUB, sliceArray(arguments)]);
};

methods.mul = function() {
  return Datum(this, [MUL, sliceArray(arguments)]);
};

methods.div = function() {
  return Datum(this, [DIV, sliceArray(arguments)]);
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
    case EQ:
      return equals(result, action[1]);
    case NE:
      return !equals(result, action[1]);
    case GT:
      return greaterThan(result, action[1]);
    case LT:
      return lessThan(result, action[1]);
    case GE:
      return greaterOrEqual(result, action[1]);
    case LE:
      return lessOrEqual(result, action[1]);
    case OR:
      return anyButFalse(result, action[1]);
    case AND:
      return noneFalse(result, action[1]);
    case ADD:
      return add(result, action[1]);
    case SUB:
      return subtract(result, action[1]);
    case MUL:
      return multiply(result, action[1]);
    case DIV:
      return divide(result, action[1]);
    case NTH:
      assertType(result, Array);
      return seq.nth(result, action[1]);
    case ACCESS:
      if (isArray(result)) {
        return seq.access(result, action[1]);
      }
      assertType(result, Object);
      return utils.getField(result, action[1]);
    case GET_FIELD:
      assertType(result, Object);
      return utils.getField(result, action[1]);
    case HAS_FIELDS:
      assertType(result, Object);
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
    case REPLACE:
      return null;
    case UPDATE:
      return null;
    case DELETE:
      return null;
  }
};

module.exports = Datum;

equals = function(result, args) {
  var arg, j, len;
  args = utils.resolve(args);
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (!utils.equals(result, arg)) {
      return false;
    }
  }
  return true;
};

greaterThan = function(result, args) {
  var arg, j, len, prev;
  args = utils.resolve(args);
  prev = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (prev <= arg) {
      return false;
    }
    prev = arg;
  }
  return true;
};

lessThan = function(result, args) {
  var arg, j, len, prev;
  args = utils.resolve(args);
  prev = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (prev >= arg) {
      return false;
    }
    prev = arg;
  }
  return true;
};

greaterOrEqual = function(result, args) {
  var arg, j, len, prev;
  args = utils.resolve(args);
  prev = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (prev < arg) {
      return false;
    }
    prev = arg;
  }
  return true;
};

lessOrEqual = function(result, args) {
  var arg, j, len, prev;
  args = utils.resolve(args);
  prev = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (prev > arg) {
      return false;
    }
    prev = arg;
  }
  return true;
};

anyButFalse = function(result, args) {
  var arg, j, len;
  args = utils.resolve(args);
  if (result !== false) {
    return result;
  }
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (arg !== false) {
      return arg;
    }
  }
  return false;
};

noneFalse = function(result, args) {
  var arg, j, len;
  args = utils.resolve(args);
  if (result === false) {
    return false;
  }
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    if (arg === false) {
      return false;
    }
  }
  return args.pop();
};

add = function(result, args) {
  var arg, j, len, total;
  assertType(result, Number);
  args = utils.resolve(args);
  total = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    assertType(arg, Number);
    total += arg;
  }
  return total;
};

subtract = function(result, args) {
  var arg, j, len, total;
  assertType(result, Number);
  args = utils.resolve(args);
  total = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    assertType(arg, Number);
    total -= arg;
  }
  return null;
};

multiply = function(result, args) {
  var arg, j, len, total;
  assertType(result, Number);
  args = utils.resolve(args);
  total = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    assertType(arg, Number);
    total *= arg;
  }
  return null;
};

divide = function(result, args) {
  var arg, j, len, total;
  assertType(result, Number);
  args = utils.resolve(args);
  total = result;
  for (j = 0, len = args.length; j < len; j++) {
    arg = args[j];
    assertType(arg, Number);
    total /= arg;
  }
  return null;
};

merge = function(result, args) {
  if (!isArray(result)) {
    return utils.merge(result, utils.resolve(args));
  }
  return result.map(function(result) {
    return utils.merge(result, utils.resolve(args));
  });
};
