var actions, arity, isConstructor, seq, seqRE, sortAscending, sortDescending, types, utils;

isConstructor = require("isConstructor");

arity = require("./arity");

types = require("./types");

utils = require("../utils");

seq = require("../utils/seq");

seqRE = /TABLE|SELECTION<ARRAY>/;

arity.set({
  nth: arity.ONE,
  offsetsOf: arity.ONE,
  contains: arity.ONE,
  orderBy: arity.ONE,
  map: arity.ONE,
  filter: arity.ONE_TWO,
  isEmpty: arity.NONE,
  count: arity.NONE,
  skip: arity.ONE,
  limit: arity.ONE,
  slice: arity.ONE_THREE
});

types.set({
  nth: types.SELECTION,
  offsetsOf: types.DATUM,
  contains: types.DATUM,
  orderBy: types.SEQUENCE,
  map: types.DATUM,
  filter: types.SEQUENCE,
  isEmpty: types.DATUM,
  count: types.DATUM,
  skip: types.SEQUENCE,
  limit: types.SEQUENCE,
  slice: types.SEQUENCE
});

actions = exports;

actions.nth = function(result, index) {
  utils.expect(result, "ARRAY");
  utils.expect(index, "NUMBER");
  if (index < -1 && seqRE.test(this.type)) {
    throw Error("Cannot use an index < -1 on a stream");
  }
  return seq.nth(result, index);
};

actions.offsetsOf = function(array, value) {
  var i, index, len, offsets, value2;
  utils.expect(array, "ARRAY");
  if (isConstructor(value, Function)) {
    throw Error("Function argument not yet implemented");
  }
  offsets = [];
  for (index = i = 0, len = array.length; i < len; index = ++i) {
    value2 = array[index];
    if (utils.equals(value2, value)) {
      offsets.push(index);
    }
  }
  return offsets;
};

actions.contains = function(array, value) {
  var i, len, value2;
  utils.expect(array, "ARRAY");
  if (isConstructor(value, Function)) {
    throw Error("Function argument not yet implemented");
  }
  for (i = 0, len = array.length; i < len; i++) {
    value2 = array[i];
    if (utils.equals(value, value2)) {
      return true;
    }
  }
  return false;
};

actions.orderBy = function(array, value) {
  var DESC, index, sorter;
  utils.expect(array, "ARRAY");
  if (isConstructor(value, Object)) {
    DESC = value.DESC, index = value.index;
  } else if (isConstructor(value, String)) {
    index = value;
  }
  utils.expect(index, "STRING");
  sorter = DESC ? sortDescending(index) : sortAscending(index);
  return array.slice().sort(sorter);
};

actions.map = function(array, iterator) {
  utils.expect(array, "ARRAY");
  return array.map(function(row) {
    return iterator._eval({
      row: row
    });
  });
};

actions.filter = function(array, filter, options) {
  var matchers;
  utils.expect(array, "ARRAY");
  if (options !== void 0) {
    utils.expect(options, "OBJECT");
  }
  if (utils.isQuery(filter)) {
    return array.filter(function(row) {
      var result;
      result = filter._eval({
        row: row
      });
      return (result !== false) && (result !== null);
    });
  }
  matchers = [];
  if (isConstructor(filter, Object)) {
    matchers.push(function(values) {
      utils.expect(values, "OBJECT");
      return true;
    });
    utils.each(filter, function(expected, key) {
      return matchers.push(function(values) {
        return utils.equals(values[key], expected);
      });
    });
  } else {
    return array;
  }
  return array.filter(function(row) {
    var i, len, matcher;
    for (i = 0, len = matchers.length; i < len; i++) {
      matcher = matchers[i];
      if (!matcher(row)) {
        return false;
      }
    }
    return true;
  });
};

actions.isEmpty = function(array) {
  utils.expect(array, "ARRAY");
  return array.length === 0;
};

actions.count = function(array) {
  utils.expect(array, "ARRAY");
  return array.length;
};

actions.skip = function(array, count) {
  utils.expect(array, "ARRAY");
  utils.expect(count, "NUMBER");
  if (count < 0 && seqRE.test(this.type)) {
    throw Error("Cannot use a negative left index on a stream");
  }
  return array.slice(count);
};

actions.limit = function(array, count) {
  utils.expect(array, "ARRAY");
  utils.expect(count, "NUMBER");
  if (count < 0) {
    throw Error("LIMIT takes a non-negative argument");
  }
  return array.slice(0, count);
};

actions.slice = function(result, args) {
  var type;
  type = utils.typeOf(result);
  if (type === "ARRAY") {
    return seq.slice(result, args);
  }
  if (type === "BINARY") {
    throw Error("`slice` does not support BINARY values (yet)");
  }
  if (type === "STRING") {
    throw Error("`slice` does not support STRING values (yet)");
  }
  throw Error("Expected ARRAY, BINARY, or STRING, but found " + type);
};

sortAscending = function(index) {
  return function(a, b) {
    if (b[index] === void 0) {
      return 1;
    }
    if (a[index] > b[index]) {
      return 1;
    }
    return -1;
  };
};

sortDescending = function(index) {
  return function(a, b) {
    if (b[index] === void 0) {
      return -1;
    }
    if (a[index] >= b[index]) {
      return -1;
    }
    return 1;
  };
};
