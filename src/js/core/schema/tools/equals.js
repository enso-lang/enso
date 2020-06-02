'use strict'

//// Equals ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Equals;

var equals = function(a, b) {
  var self = this;
  return EqualsClass.equals(a, b);
};

class EqualsClass {
  static new(...args) { return new EqualsClass(...args) };

  static equals(a, b) {
    var self = this;
    return self.new().equals(a, b);
  };

  constructor() {
    var self = this;
    self.memo$ = Enso.EMap.new();
  };

  equals(a, b) {
    var self = this, res, a_val, b_val;
    if (a == b) {
      return true;
    } else if ((a == null || b == null) || a.schema_class().name() != b.schema_class().name()) {
      return false;
    } else if (self.memo$.get$([a, b])) {
      return true;
    } else {
      res = true;
      self.memo$ .set$([a, b], true);
      a.schema_class().fields().each(function(field) {
        a_val = a.get$(field.name());
        b_val = b.get$(field.name());
        if (Enso.System.test_type(field.type(), "Primitive")) {
          if (a_val != b_val) {
            return res = false;
          }
        } else if (! field.many()) {
          if (! self.equals(a_val, b_val)) {
            puts(Enso.S("fail2 ", a_val, " ", b_val));
            return res = false;
          }
        } else if (Enso.System.test_type(a_val, Factory.List)) {
          if (! self.equals_list(a_val, b_val)) {
            return res = false;
          }
        } else if (Enso.System.test_type(a_val, Factory.Set)) {
          if (! self.equals_set(a_val, b_val)) {
            return res = false;
          }
        }
      });
      return res;
    }
  };

  equals_list(l1, l2) {
    var self = this, res;
    if (l1.size_M() != l2.size_M()) {
      return false;
    } else {
      res = true;
      l1.keys().each(function(i) {
        if (! self.equals(l1.get$(i), l2.get$(i))) {
          return res = false;
        }
      });
      return res;
    }
  };

  equals_set(l1, l2) {
    var self = this, res;
    if (l1.size_M() != l2.size_M()) {
      return false;
    } else {
      res = true;
      l1.keys().each(function(i) {
        if (! self.equals(l1.get$(i), l2.get$(i))) {
          return res = false;
        }
      });
      return res;
    }
  };
};

Equals = {
  equals: equals,
  EqualsClass: EqualsClass,
};
module.exports = Equals ;
