var cache, isConstructor, seqRE, types;

isConstructor = require("isConstructor");

seqRE = /TABLE|SELECTION<ARRAY>/;

cache = Object.create(null);

types = exports;

types.get = function(actionId) {
  return cache[actionId];
};

types.set = function(values) {
  var actionId, value;
  for (actionId in values) {
    value = values[actionId];
    cache[actionId] = value;
  }
};

types.DATUM = "DATUM";

types.SEQUENCE = function(ctx) {
  if (seqRE.test(ctx.type)) {
    return "SELECTION<ARRAY>";
  }
  return "DATUM";
};

types.SELECTION = function(ctx) {
  if (seqRE.test(ctx.type)) {
    return "SELECTION";
  }
  return "DATUM";
};

types.BRACKET = function(ctx, args) {
  if (!isConstructor(args[0], String)) {
    if (seqRE.test(ctx.type)) {
      return "SELECTION";
    }
  }
  return "DATUM";
};
