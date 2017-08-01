var assertType, hasFields, isArray, isConstructor, seq, sortAscending, sortDescending, utils;

isConstructor = require("isConstructor");

assertType = require("assertType");

utils = require(".");

isArray = Array.isArray;

seq = exports;

seq.access = function(array, value) {
  if (utils.isQuery(value)) {
    value = value._run();
  }
  if (isConstructor(value, Number)) {
    return utils.nth(array, value);
  }
  if (isConstructor(value, String)) {
    return seq.getField(array, value);
  }
  throw Error("Expected a Number or String!");
};

seq.getField = function(array, attr) {
  var i, len, results, value;
  if (utils.isQuery(attr)) {
    attr = attr._run();
  }
  assertType(attr, String);
  results = [];
  for (i = 0, len = array.length; i < len; i++) {
    value = array[i];
    assertType(value, Object);
    if (value.hasOwnProperty(attr)) {
      results.push(value[attr]);
    }
  }
  return results;
};

seq.hasFields = function(array, attrs) {
  var attr, i, j, len, len1, results, value;
  for (i = 0, len = attrs.length; i < len; i++) {
    attr = attrs[i];
    assertType(attr, String);
  }
  results = [];
  for (j = 0, len1 = array.length; j < len1; j++) {
    value = array[j];
    assertType(value, Object);
    if (hasFields(value, attrs)) {
      results.push(value);
    }
  }
  return results;
};

seq.offsetsOf = function(array, value) {
  var i, index, len, offsets, value2;
  if (value === void 0) {
    throw Error("Argument 1 to offsetsOf may not be `undefined`");
  }
  if (utils.isQuery(value)) {
    value = value._run();
  }
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

seq.filter = function(array, filter, options) {
  var matchers;
  if (filter === void 0) {
    throw Error("Argument 1 to filter may not be `undefined`");
  }
  if (utils.isQuery(filter)) {
    filter = filter._run();
  }
  if (options !== void 0) {
    assertType(options, Object);
  }
  matchers = [];
  if (isConstructor(filter, Object)) {
    matchers.push(function(values) {
      assertType(values, Object);
      return true;
    });
    Object.keys(filter).forEach(function(key) {
      var value;
      value = utils.resolve(filter[key]);
      return matchers.push(function(values) {
        return utils.equals(values[key], value);
      });
    });
  } else if (isConstructor(filter, Function)) {
    throw Error("Filter functions are not implemented yet");
  } else {
    return array.slice();
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

seq.sort = function(array, value) {
  var key, sort, sorter;
  if (value === void 0) {
    throw Error("Argument 1 to orderBy may not be `undefined`");
  }
  if (utils.isQuery(value)) {
    value = value._run();
  }
  if (isArray(value)) {
    sort = value[0], key = value[1];
  } else if (isConstructor(value, String)) {
    sort = "asc";
    key = value;
  }
  if (sort === "asc") {
    sorter = sortAscending(key);
  } else if (sort === "desc") {
    sorter = sortDescending(key);
  } else {
    throw Error("Invalid sort algorithm: '" + sort + "'");
  }
  assertType(key, String);
  return array.slice().sort(sorter);
};

seq.limit = function(array, n) {
  if (utils.isQuery(n)) {
    n = n._run();
  }
  assertType(n, Number);
  if (n < 0) {
    throw Error("Cannot call `limit` with a negative number");
  }
  return array.slice(0, n);
};

seq.slice = function(array, args) {
  var endIndex, options, startIndex;
  if ((args.length < 1) || (args.length > 3)) {
    throw Error("Expected between 1 and 3 arguments but found " + args.length);
  }
  args = utils.resolve(args);
  options = isConstructor(args[args.length - 1], Object) ? args.pop() : {};
  startIndex = args[0], endIndex = args[1];
  if (endIndex == null) {
    endIndex = array.length;
  }
  assertType(startIndex, Number);
  assertType(endIndex, Number);
  if (options.leftBound === "open") {
    startIndex += 1;
  }
  if (options.rightBound === "closed") {
    endIndex += 1;
  }
  return array.slice(startIndex, endIndex);
};

seq.pluck = function(rows, args) {
  return rows.map(function(row) {
    return utils.pluck(row, args);
  });
};

seq.without = function(rows, args) {
  return rows.map(function(row) {
    return utils.without(row, args);
  });
};

hasFields = function(value, attrs) {
  var attr, i, len;
  for (i = 0, len = attrs.length; i < len; i++) {
    attr = attrs[i];
    if (!value.hasOwnProperty(attr)) {
      return false;
    }
  }
  return true;
};

sortAscending = function(key) {
  return function(a, b) {
    if (b[key] === void 0) {
      return 1;
    }
    if (a[key] > b[key]) {
      return 1;
    }
    return -1;
  };
};

sortDescending = function(key) {
  return function(a, b) {
    if (b[key] === void 0) {
      return -1;
    }
    if (a[key] >= b[key]) {
      return -1;
    }
    return 1;
  };
};
