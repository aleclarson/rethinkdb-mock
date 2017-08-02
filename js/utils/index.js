var arrayEquals, assertType, isArray, isArrayOrObject, isConstructor, merge, objectEquals, pluckWithArray, pluckWithObject, resolveArray, resolveObject, sliceArray, update, utils;

isConstructor = require("isConstructor");

assertType = require("assertType");

sliceArray = require("sliceArray");

isArray = Array.isArray;

utils = exports;

utils.isQuery = function(queryTypes, value) {
  if (!value) {
    return false;
  }
  if (~queryTypes.indexOf(value.constructor)) {
    return true;
  }
  return false;
};

utils["do"] = function(self, callback) {
  var getInput, input, query, run;
  query = callback(self);
  if (query === void 0) {
    throw Error("Return value may not be `undefined`");
  }
  if (!utils.isQuery(query)) {
    query = self._db.expr(query);
  }
  input = void 0;
  getInput = function() {
    if (input !== void 0) {
      return input;
    }
    return input = self._query._run();
  };
  self._run = run = function() {
    var output;
    self._run = getInput;
    output = query._run();
    input = void 0;
    self._run = run;
    return output;
  };
  return self;
};

utils.getField = function(value, attr) {
  if (utils.isQuery(attr)) {
    attr = attr._run();
  }
  assertType(attr, String);
  if (!value.hasOwnProperty(attr)) {
    throw Error("No attribute `" + attr + "` in object");
  }
  return value[attr];
};

utils.hasFields = function(value, attrs) {
  var attr, i, index, len;
  for (index = i = 0, len = attrs.length; i < len; index = ++i) {
    attr = attrs[index];
    if (attr === void 0) {
      throw Error("Argument " + index + " to hasFields may not be `undefined`");
    }
    if (!isConstructor(attr, String)) {
      throw Error("Invalid path argument");
    }
    if (!value.hasOwnProperty(attr)) {
      return false;
    }
  }
  return true;
};

utils.equals = function(value1, value2) {
  value2 = utils.resolve(value2);
  if (isArray(value1)) {
    if (!isArray(value2)) {
      return false;
    }
    return arrayEquals(value1, value2);
  }
  if (isConstructor(value1, Object)) {
    if (!isConstructor(value2, Object)) {
      return false;
    }
    return objectEquals(value1, value2);
  }
  return value1 === value2;
};

utils.flatten = function(input, output) {
  var i, len, value;
  if (output == null) {
    output = [];
  }
  assertType(input, Array);
  assertType(output, Array);
  for (i = 0, len = input.length; i < len; i++) {
    value = input[i];
    if (isArray(value)) {
      utils.flatten(value, output);
    } else {
      output.push(value);
    }
  }
  return output;
};

utils.pluck = function(input, keys) {
  assertType(input, Object);
  assertType(keys, Array);
  return pluckWithArray(keys, input, {});
};

utils.without = function(input, keys) {
  var key, output, value;
  assertType(input, Object);
  assertType(keys, Array);
  keys = utils.flatten(keys);
  output = {};
  for (key in input) {
    value = input[key];
    if (!~keys.indexOf(key)) {
      output[key] = value;
    }
  }
  return output;
};

utils.merge = function(output, inputs) {
  var i, input, len;
  assertType(output, Object);
  assertType(inputs, Array);
  output = utils.clone(output);
  for (i = 0, len = inputs.length; i < len; i++) {
    input = inputs[i];
    output = merge(output, input);
  }
  if (isArray(output)) {
    return utils.resolve(output);
  }
  return output;
};

utils.update = function(object, patch) {
  if (patch.hasOwnProperty("id")) {
    if (patch.id !== object.id) {
      throw Error("Primary key `id` cannot be changed");
    }
  }
  return !!update(object, patch);
};

utils.clone = function(values) {
  var clone, key, value;
  if (values === null) {
    return null;
  }
  if (isArray(values)) {
    return values.map(function(value) {
      if (isArrayOrObject(value)) {
        return utils.clone(value);
      } else {
        return value;
      }
    });
  }
  clone = {};
  for (key in values) {
    value = values[key];
    clone[key] = isArrayOrObject(value) ? utils.clone(value) : value;
  }
  return clone;
};

utils.resolve = function(value) {
  if (isArray(value)) {
    return resolveArray(value);
  }
  if (isConstructor(value, Object)) {
    return resolveObject(value);
  }
  if (utils.isQuery(value)) {
    return value._run();
  }
  return value;
};

isArrayOrObject = function(value) {
  return isArray(value) || isConstructor(value, Object);
};

arrayEquals = function(array1, array2) {
  var i, index, len, value1;
  if (array1.length !== array2.length) {
    return false;
  }
  for (index = i = 0, len = array1.length; i < len; index = ++i) {
    value1 = array1[index];
    if (!utils.equals(value1, array2[index])) {
      return false;
    }
  }
  return true;
};

objectEquals = function(object1, object2) {
  var i, j, key, keys, len, len1, ref;
  keys = Object.keys(object1);
  ref = Object.keys(object2);
  for (i = 0, len = ref.length; i < len; i++) {
    key = ref[i];
    if (!~keys.indexOf(key)) {
      return false;
    }
  }
  for (j = 0, len1 = keys.length; j < len1; j++) {
    key = keys[j];
    if (!utils.equals(object1[key], object2[key])) {
      return false;
    }
  }
  return true;
};

pluckWithArray = function(array, input, output) {
  var i, key, len;
  array = utils.flatten(array);
  for (i = 0, len = array.length; i < len; i++) {
    key = array[i];
    if (typeof key === "string") {
      if (input.hasOwnProperty(key)) {
        output[key] = input[key];
      }
    } else if (isConstructor(key, Object)) {
      pluckWithObject(key, input, output);
    } else {
      throw TypeError("Invalid path argument");
    }
  }
  return output;
};

pluckWithObject = function(object, input, output) {
  var key, value;
  for (key in object) {
    value = object[key];
    if (value === true) {
      if (input.hasOwnProperty(key)) {
        output[key] = input[key];
      }
    } else if (typeof value === "string") {
      if (isConstructor(input[key], Object)) {
        output[key] = {};
        output[key][value] = input[key][value];
      }
    } else if (isArray(value)) {
      if (isConstructor(input[key], Object)) {
        output[key] = pluckWithArray(value, input[key], output);
      }
    } else if (isConstructor(value, Object)) {
      if (isConstructor(input[key], Object)) {
        output[key] = pluckWithObject(value, input[key], {});
      }
    } else {
      throw TypeError("Invalid path argument");
    }
  }
  return output;
};

merge = function(output, input) {
  var key, value;
  if (!isConstructor(input, Object)) {
    return input;
  }
  if (!isConstructor(output, Object)) {
    output = {};
  }
  for (key in input) {
    value = input[key];
    output[key] = isConstructor(output[key], Object) ? merge(output[key], value) : value;
  }
  return output;
};

update = function(output, input) {
  var changes, key, value;
  changes = 0;
  for (key in input) {
    value = input[key];
    if (isConstructor(value, Object)) {
      if (!isConstructor(output[key], Object)) {
        changes += 1;
        output[key] = utils.clone(value);
        continue;
      }
      changes += update(output[key], value);
    } else if (isArray(value)) {
      if (isArray(output[key])) {
        if (arrayEquals(value, output[key])) {
          continue;
        }
      }
      changes += 1;
      output[key] = utils.clone(value);
    } else if (value !== output[key]) {
      changes += 1;
      output[key] = value;
    }
  }
  return changes;
};

resolveArray = function(values) {
  var clone, i, index, len, value;
  clone = [];
  for (index = i = 0, len = values.length; i < len; index = ++i) {
    value = values[index];
    if (value === void 0) {
      throw Error("Cannot wrap undefined with r.expr()");
    }
    if (isArray(value)) {
      clone.push(resolveArray(value));
    } else if (isConstructor(value, Object)) {
      clone.push(resolveObject(value));
    } else if (utils.isQuery(value)) {
      clone.push(value._run());
    } else {
      clone.push(value);
    }
  }
  return clone;
};

resolveObject = function(values) {
  var clone, key, value;
  clone = {};
  for (key in values) {
    value = values[key];
    if (value === void 0) {
      throw Error("Object field '" + key + "' may not be undefined");
    }
    if (isArray(value)) {
      clone[key] = resolveArray(value);
    } else if (isConstructor(value, Object)) {
      clone[key] = resolveObject(value);
    } else if (utils.isQuery(value)) {
      clone[key] = value._run();
    } else {
      clone[key] = value;
    }
  }
  return clone;
};
