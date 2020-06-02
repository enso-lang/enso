'use strict'

//// Schema ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Schema;

var object_key = function(obj) {
  var self = this;
  return obj.get$(obj.schema_class().key().name());
};

var lookup = function(block, obj) {
  var self = this, res;
  res = block(obj);
  if (res) {
    return res;
  } else if (obj.supers().empty_P()) {
    return null;
  } else {
    return obj.supers().find_first(function(o) {
      return Schema.lookup(block, o);
    });
  }
};

var subclass_P = function(a, b) {
  var self = this, res;
  res = Schema.subclassb(a, b);
  return res;
};

var subclassb = function(a, b) {
  var self = this, an, bn;
  an = Enso.System.test_type(a, String)
    ? a
    : a.name();
  bn = Enso.System.test_type(b, String)
    ? b
    : b.name();
  if (a == null || b == null) {
    return false;
  } else if (an == bn) {
    return true;
  } else {
    return a.supers().any_P(function(sup) {
      return Schema.subclassb(sup, b);
    });
  }
};

var class_minimum = function(a, b) {
  var self = this;
  if (b == null) {
    return a;
  } else if (a == null) {
    return b;
  } else if (Schema.subclass_P(a, b)) {
    return a;
  } else if (Schema.subclass_P(b, a)) {
    return b;
  } else {
    return null;
  }
};

var map = function(block, obj) {
  var self = this, res;
  if (obj == null) {
    return null;
  } else {
    res = block(obj);
    obj.schema_class().fields().each(function(f) {
      if (f.traversal() && ! Enso.System.test_type(f.type(), "Primitive")) {
        if (! f.many()) {
          return Schema.map(block, obj.get$(f.name()));
        } else {
          return res.get$(f.name()).keys().each(function(k) {
            return Schema.map(block, obj.get$(f.name()).get$(k));
          });
        }
      }
    });
    return res;
  }
};

Schema = {
  object_key: object_key,
  lookup: lookup,
  subclass_P: subclass_P,
  subclassb: subclassb,
  class_minimum: class_minimum,
  map: map,
};
module.exports = Schema ;
