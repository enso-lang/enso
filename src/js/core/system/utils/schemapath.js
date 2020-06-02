'use strict'

//// Schemapath ////

var cwd = process.cwd() + '/';
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Equals = require(cwd + "core/schema/tools/equals.js");
var Enso = require(cwd + "enso.js");

var Schemapath;

var make = function(start = null) {
  var self = this;
  return Path.new(start);
};

class Path extends Enso.mix(Enso.EnsoBaseClass, Interpreter.Dispatcher) {
  static new(...args) { return new Path(...args) };

  static set_factory(factory) {
    var self = this;
    return Path.new(factory.EVar("root")).set_factory(factory);
  };

  path() { return this.path$ };

  set_factory(factory) {
    var self = this;
    return this.constructor.factory$$ = factory;
  };

  constructor(path = null) {
    var path;
    super();
    var self = this;
    if (path == null) {
      path = this.constructor.factory$$.EVar("root");
    }
    self.path$ = path;
  };

  field(name) {
    var self = this;
    return Path.new(this.constructor.factory$$.EField(self.path$, name));
  };

  key(key) {
    var self = this;
    return Path.new(this.constructor.factory$$.ESubscript(self.path$, this.constructor.factory$$.EStrConst(key)));
  };

  index(index) {
    var self = this;
    return Path.new(this.constructor.factory$$.ESubscript(self.path$, this.constructor.factory$$.EIntConst(index)));
  };

  equals(other) {
    var self = this;
    return Equals.equals(self.path$, other.path());
  };

  deref_P(root) {
    var self = this;
    try {
      return ! (self.deref(root) == null);
    } catch (DUMMY) {
      return false;
    }
  };

  to_s() {
    var self = this;
    return self.to_s_path(self.path$);
  };

  to_s_path(path) {
    var self = this;
    return self.dispatch_obj("to_s", path);
  };

  to_s_EVar(obj) {
    var self = this;
    return obj.name();
  };

  to_s_EConst(obj) {
    var self = this;
    return obj.val();
  };

  to_s_EField(obj) {
    var self = this;
    return Enso.S(self.to_s_path(obj.e()), ".", obj.fname());
  };

  to_s_ESubscript(obj) {
    var self = this;
    return Enso.S(self.to_s_path(obj.e()), "[", self.to_s_path(obj.sub()), "]");
  };

  deref(root) {
    var self = this;
    return self.dynamic_bind(function() {
      return self.eval();
    }, Enso.EMap.new({root: root}));
  };

  eval_M(path = self.path$) {
    var self = this;
    return self.dispatch_obj("eval", path);
  };

  eval_EVar(obj) {
    var self = this;
    if (! self.D$.include_P(obj.name().to_sym())) {
      self.raise(Enso.S("undefined variable ", obj.name()));
    }
    return self.D$.get$(obj.name().to_sym());
  };

  eval_EConst(obj) {
    var self = this;
    return obj.val();
  };

  eval_EField(obj) {
    var self = this;
    return self.eval_M(obj.e()).get$(obj.fname());
  };

  eval_ESubscript(obj) {
    var self = this;
    return self.eval_M(obj.e()).get$(self.eval_M(obj.sub()));
  };

  assign(root, val) {
    var self = this, obj;
    obj = self.path$;
    if (Enso.System.test_type(obj, "EField")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()) .set$(obj.fname(), val);
      }, Enso.EMap.new({root: root}));
    } else if (Enso.System.test_type(obj, "ESubscript")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()) .set$(self.eval_M(obj.sub()), val);
      }, Enso.EMap.new({root: root}));
    }
  };

  insert(root, val) {
    var self = this, obj;
    obj = self.path$;
    if (Enso.System.test_type(obj, "EField")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()) .set$(obj.fname(), val);
      }, Enso.EMap.new({root: root}));
    } else if (Enso.System.test_type(obj, "ESubscript")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()).insert(self.eval_M(obj.sub()), val);
      }, Enso.EMap.new({root: root}));
    }
  };

  delete_M(root) {
    var self = this, obj;
    obj = self.path$;
    if (Enso.System.test_type(obj, "EField")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()) .set$(obj.fname(), null);
      }, Enso.EMap.new({root: root}));
    } else if (Enso.System.test_type(obj, "ESubscript")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()).delete_M(self.eval_M(obj));
      }, Enso.EMap.new({root: root}));
    }
  };

  type(root, obj = self.path$) {
    var self = this;
    if (Enso.System.test_type(obj, "EField")) {
      return self.dynamic_bind(function() {
        return self.eval_M(obj.e()).schema_class().fields().get$(obj.fname());
      }, Enso.EMap.new({root: root}));
    } else if (Enso.System.test_type(obj, "ESubscript")) {
      return self.type(root, obj.e());
    }
  };

  assign_and_coerce(root, value) {
    var self = this, obj, fld, value;
    if (! self.lvalue_P()) {
      self.raise(Enso.S("Can only assign to lvalues not to ", self));
    }
    obj = self.owner().deref(root);
    fld = obj.schema_class().fields().get$(self.last().name());
    if (Enso.System.test_type(fld.type(), "Primitive")) {
      switch (fld.type().name()) {
        case "str":
          value = value.to_s();
          break;
        case "int":
          value = value.to_i();
          break;
        case "bool":
          value = value.to_s() == "true"
            ? true
            : false;
          break;
        case "real":
          value = value.to_f();
          break;
        default:
          self.raise(Enso.S("Unknown primitive type: ", fld.type().name()));
          break;
      }
    }
    return self.owner().deref(root) .set$(self.last().name(), value);
  };
};

Schemapath = {
  make: make,
  Path: Path,
};
module.exports = Schemapath ;
