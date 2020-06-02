'use strict'

//// Union ////

var cwd = process.cwd() + '/';
var Factory = require(cwd + "core/schema/code/factory.js");
var Enso = require(cwd + "enso.js");

var Union;

var Copy = function(factory, a) {
  var self = this;
  return CopyInto.new(factory).copy(a, null).finalize();
};

var Clone = function(a) {
  var self = this;
  return Copy(a.factory(), a);
};

var Union = function(factory, ...parts) {
  var self = this, copier, result;
  copier = CopyInto.new(factory);
  result = null;
  parts.each(function(part) {
    return result = copier.copy(part, result);
  });
  return result.finalize();
};

var union = function(a, b) {
  var self = this, f;
  f = Factory.SchemaFactory.new(a.graph_identity().schema());
  return Union(f, a, b);
};

class CopyInto {
  static new(...args) { return new CopyInto(...args) };

  constructor(factory) {
    var self = this;
    self.memo$ = Enso.EMap.new();
    self.factory$ = factory;
  };

  copy(a, b) {
    var self = this;
    self.build(a, b);
    return self.link(true, a, b);
  };

  build(a, b) {
    var self = this, new_V, a_val, b_val;
    if (! (a == null)) {
      if ((a && b) && a.schema_class().name() != b.schema_class().name()) {
        self.raise(Enso.S("Union of incompatible objects ", a, " and ", b));
      }
      self.memo$ .set$(a.identity(), new_V = b || self.factory$.get$(a.schema_class().name()));
      return new_V.schema_class().fields().each(function(field) {
        a_val = ((function() {
          try {
            return a.get$(field.name());
          } catch (DUMMY) {
            return null;
          }
        })());
        b_val = ((function() {
          try {
            return b.get$(field.name());
          } catch (DUMMY) {
            return null;
          }
        })());
        if (! (a_val == null) || ! (b_val == null)) {
          if (Enso.System.test_type(field.type(), "Primitive")) {
            if (! (a_val == null)) {
              if ((a && b) && a_val != b_val) {
                puts(Enso.S("UNION WARNING: changing ", new_V, ".", field.name(), " from '", b_val, "' to '", a_val, "'"));
              }
              return new_V .set$(field.name(), a_val);
            }
          } else if (field.traversal()) {
            if (! field.many()) {
              return self.build(a_val, b_val);
            } else {
              return a_val.each_with_match(function(a_item, b_item) {
                return self.build(a_item, b_item);
              }, b_val);
            }
          }
        } else if (! (new_V.get$(field.name()) == null)) {
          return puts(Enso.S("skipping ", new_V, ".", field.name(), " as ", new_V.get$(field.name())));
        }
      });
    }
  };

  link(traversal, a, b) {
    var self = this, new_V, a_val, b_val, val, item;
    if (a == null) {
      return b;
    } else {
      new_V = self.memo$.get$(a.identity());
      if (! new_V) {
        self.p(self.memo$);
        self.raise(Enso.S("Traversal did not visit every object a=", a, " b=", b));
      }
      if (traversal) {
        a.schema_class().fields().each(function(field) {
          a_val = a.get$(field.name());
          b_val = b && b.get$(field.name());
          if (! Enso.System.test_type(field.type(), "Primitive")) {
            if (! field.many()) {
              val = self.link(field.traversal(), a_val, b_val);
              return new_V .set$(field.name(), val);
            } else {
              return a_val.each_with_match(function(a_item, b_item) {
                item = self.link(field.traversal(), a_item, b_item);
                return new_V.get$(field.name()).push(item);
              }, b_val);
            }
          }
        });
      }
      return new_V;
    }
  };
};

Union = {
  Copy: Copy,
  Clone: Clone,
  Union: Union,
  union: union,
  CopyInto: CopyInto,
};
module.exports = Union ;
