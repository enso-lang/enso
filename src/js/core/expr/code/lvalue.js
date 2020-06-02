'use strict'

//// Lvalue ////

var cwd = process.cwd() + '/';
var Eval = require(cwd + "core/expr/code/eval.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Env = require(cwd + "core/expr/code/env.js");
var Enso = require(cwd + "enso.js");

var Lvalue;

var lvalue = function(obj, args = Enso.EMap.new()) {
  var self = this, interp;
  interp = LValueExprC.new();
  return interp.dynamic_bind(function() {
    return interp.lvalue(obj);
  }, args);
};

class Address {
  static new(...args) { return new Address(...args) };

  constructor(array, index) {
    var self = this;
    self.array$ = array;
    self.index$ = index;
    if (! self.array$.has_key_P(self.index$)) {
      self.array$ .set$(self.index$, null);
    }
  };

  array() { return this.array$ };

  index() { return this.index$ };

  set_value(val) {
    var self = this, val;
    if (self.type()) {
      switch (self.type().name()) {
        case "int":
          val = val.to_i();
          break;
        case "str":
          val = val.to_s();
          break;
        case "real":
          val = val.to_f();
          break;
      }
    }
    try {
      return self.array$ .set$(self.index$, val);
    } catch (DUMMY) {
    }
  };

  set(val) {
    var self = this, val;
    if (self.type()) {
      switch (self.type().name()) {
        case "int":
          val = val.to_i();
          break;
        case "str":
          val = val.to_s();
          break;
        case "real":
          val = val.to_f();
          break;
      }
    }
    try {
      return self.array$ .set$(self.index$, val);
    } catch (DUMMY) {
    }
  };

  value() {
    var self = this;
    return self.array$.get$(self.index$);
  };

  get() {
    var self = this;
    return self.array$.get$(self.index$);
  };

  to_s() {
    var self = this;
    return Enso.S(self.array$, "[", self.index$, "]");
  };

  type() {
    var self = this;
    if (Enso.System.test_type(self.array$, Env.ObjEnv)) {
      return self.array$.type(self.index$);
    } else {
      return null;
    }
  };

  object() {
    var self = this;
    if (Enso.System.test_type(self.array$, Env.ObjEnv)) {
      return self.array$.obj();
    } else {
      return null;
    }
  };
};

function LValueExpr(parent) {
  return class extends Enso.mix(parent, Eval.EvalExpr, Interpreter.Dispatcher) {
    lvalue(obj) {
      var self = this;
      return self.dispatch_obj("lvalue", obj);
    };

    lvalue_EField(obj) {
      var self = this;
      return Address.new(Env.ObjEnv.new(self.eval_M(obj.e())), obj.fname());
    };

    lvalue_EVar(obj) {
      var self = this;
      return Address.new(self.D$.get$("env"), obj.name());
    };

    lvalue__P(obj) {
      var self = this;
      return null;
    }; }};

class LValueExprC extends Enso.mix(Enso.EnsoBaseClass, LValueExpr) {
  static new(...args) { return new LValueExprC(...args) };

};

Lvalue = {
  lvalue: lvalue,
  Address: Address,
  LValueExpr: LValueExpr,
  LValueExprC: LValueExprC,
};
module.exports = Lvalue ;
