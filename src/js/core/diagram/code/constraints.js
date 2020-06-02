'use strict'

//// Constraints ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Constraints;

class ConstraintSystem {
  static new(...args) { return new ConstraintSystem(...args) };

  constructor() {
    var self = this;
    self.vars$ = Enso.EMap.new();
    self.number$ = 0;
  };

  variable(name = Enso.S("v", self.number$), value = null) {
    var self = this;
    self.number$ = self.number$ + 1;
    return Variable.new(name, value);
  };

  value(n) {
    var self = this;
    return self.variable(Enso.S("(", n, ")"), n);
  };
};

class Constant {
  static new(...args) { return new Constant(...args) };

  constructor(val) {
    var self = this;
    self.value$ = val;
  };

  add_listener(l) {
    var self = this;
  };

  internal_evaluate(path) {
    var self = this;
    return self.value$;
  };

  value() {
    var self = this;
    return self.value$;
  };

  to_i() {
    var self = this;
    return self.value().to_i();
  };

  to_s() {
    var self = this;
    if (self.value() == null) {
      return "nil";
    } else {
      return self.value().to_s();
    }
  };

  to_ary() {
    var self = this;
    return [self];
  };
};

class Variable extends Constant {
  static new(...args) { return new Variable(...args) };

  constructor(name, val = null) {
    super(val);
    var self = this;
    self.name$ = name;
    self.dependencies$ = [];
    self.vars$ = [];
    self.bounds$ = null;
  };

  add(other) {
    var self = this;
    return self.define_result("add", other);
  };

  sub(other) {
    var self = this;
    return self.define_result("sub", other);
  };

  mul(other) {
    var self = this;
    return self.define_result("mul", other);
  };

  div(other) {
    var self = this;
    return self.define_result("div", other);
  };

  round() {
    var self = this;
    return self.define_result("round");
  };

  to_int() {
    var self = this;
    return self.define_result("to_int");
  };

  max(other = self.raise("MAX WITH UNDEFINED")) {
    var self = this;
    if (Enso.System.test_type(other, Variable)) {
      other.add_listener(self);
    }
    if (self.bounds$ == null) {
      self.bounds$ = [];
    }
    return self.bounds$.push(other);
  };

  test(a, b) {
    var self = this, variable;
    variable = Variable.new(Enso.S("test", self.to_s()));
    variable.internal_define(function(v, ra, rb) {
      return v.test(ra, rb);
    }, self, a, b);
    return variable;
  };

  new_var_method(block) {
    var self = this, variable;
    variable = Variable.new(Enso.S("p", self.to_s()));
    variable.internal_define(block, self);
    return variable;
  };

  define_result(m, ...args) {
    var self = this, variable;
    if (! ["add", "sub", "mul", "div", "round", "to_int"].include_P(m)) {
      self.raise(Enso.S("undefined method ", m));
    }
    variable = Variable.new(Enso.S("p", self.to_s(), args.to_s()));
    variable.internal_define(function(...values) {
      return self.do_op(m, ...values);
    }, self, ...args);
    return variable;
  };

  do_op(op, ...values) {
    var self = this;
    switch (op) {
      case "add":
        return values.get$(0) + values.get$(1);
      case "sub":
        return values.get$(0) - values.get$(1);
      case "mul":
        return values.get$(0) * values.get$(1);
      case "div":
        return values.get$(0) / values.get$(1);
      case "round":
        return values.get$(0).round();
      case "to_int":
        return values.get$(0).to_int();
    }
  };

  internal_define(block, ...vars) {
    var self = this;
    if (self.block$) {
      self.raise("DOUBLE defined Var");
    }
    self.vars$ = vars.map(function(v) {
      if (v == null) {
        return self.raise(Enso.S("Unbound variable ", v.toString()));
      } else if (Enso.System.test_type(v, Constant) || Enso.System.test_type(v, Variable)) {
        return v;
      } else {
        return Constant.new(v);
      }
    });
    self.vars$.each(function(v) {
      return v.add_listener(self);
    });
    return self.block$ = block;
  };

  add_listener(x) {
    var self = this;
    return self.dependencies$.push(x);
  };

  value() {
    var self = this;
    if (! self.value$) {
      self.internal_evaluate();
    }
    return self.value$;
  };

  set_value(x) {
    var self = this;
    self.block$ = null;
    self.internal_notify_change();
    return self.value$ = x;
  };

  redo_max() {
    var self = this;
    self.value$ = null;
    return self.internal_notify_change();
  };

  internal_notify_change() {
    var self = this;
    self.dependencies$.each(function(variable) {
      return variable.internal_notify_change();
    });
    if (! (self.block$ == null)) {
      return self.value$ = null;
    }
  };

  internal_evaluate(path = []) {
    var self = this, val, vals;
    if (path.include_P(self)) {
      self.raise(Enso.S("circular constraint ", path.map(function(x) {
        return x.to_s();
      })));
    }
    if (self.bounds$) {
      self.value$ = null;
    }
    if (self.block$) {
      path.push(self);
      vals = self.vars$.map(function(variable) {
        val = variable.internal_evaluate(path);
        if (val == null) {
          puts(Enso.S("WARNING: undefined variable '", variable, "'"));
          val = 10;
        }
        return val;
      });
      path.pop();
      self.value$ = self.block$(...vals);
    }
    if (self.bounds$) {
      self.bounds$.each(function(b) {
        if (Enso.System.test_type(b, Variable)) {
          val = b.value();
        } else {
          val = b;
        }
        if (self.value$ == null || self.value$ < val) {
          return self.value$ = val;
        }
      });
    }
    return self.value$;
  };
};

Constraints = {
  ConstraintSystem: ConstraintSystem,
  Constant: Constant,
  Variable: Variable,
};
module.exports = Constraints ;
