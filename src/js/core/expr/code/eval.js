'use strict'

//// Eval ////

var cwd = process.cwd() + '/';
var Schema = require(cwd + "core/system/library/schema.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Enso = require(cwd + "enso.js");

var Eval;

var make_default_const = function(factory, type) {
  var self = this;
  switch (type) {
    case "int":
      return factory.EIntConst();
    case "str":
      return factory.EStrConst();
    case "bool":
      return factory.EBoolConst();
    case "real":
      return factory.ERealConst();
  }
};

var eval_M = function(obj, args = Enso.EMap.new({env: Enso.EMap.new()})) {
  var self = this, interp;
  interp = EvalExprC.new();
  return interp.dynamic_bind(function() {
    return interp.eval_M(obj);
  }, args);
};

var make_const = function(factory, val) {
  var self = this;
  if (Enso.System.test_type(val, String)) {
    return factory.EStrConst(val);
  } else if (Enso.System.test_type(val, Enso.Integer) && val % 1 == 0) {
    return factory.EIntConst(val);
  } else if (Enso.System.test_type(val, Float) && val % 1 != 0) {
    return factory.ERealConst(val);
  } else if (Enso.System.test_type(val, Enso.TrueClass) || Enso.System.test_type(val, Enso.FalseClass)) {
    return factory.EBoolConst(val);
  } else if (val == null) {
    return factory.ENil();
  } else {
    return val;
  }
};

function EvalExpr(parent) {
  return class extends Enso.mix(parent, Interpreter.Dispatcher) {
    eval_M(obj) {
      var self = this;
      return self.dispatch_obj("eval", obj);
    };

    eval_ETernOp(obj) {
      var self = this;
      if (self.eval_M(obj.e1())) {
        return self.eval_M(obj.e2());
      } else {
        return self.eval_M(obj.e3());
      }
    };

    eval_EBinOp(obj) {
      var self = this, a, b;
      switch (obj.op()) {
        case "&":
          return self.eval_M(obj.e1()) && self.eval_M(obj.e2());
        case "|":
          return self.eval_M(obj.e1()) || self.eval_M(obj.e2());
        case "eql?":
          a = self.eval_M(obj.e1());
          b = self.eval_M(obj.e2());
          return a == b;
        case "!=":
          return self.eval_M(obj.e1()) != self.eval_M(obj.e2());
        case "+":
          return self.eval_M(obj.e1()) + self.eval_M(obj.e2());
        case "*":
          return self.eval_M(obj.e1()) * self.eval_M(obj.e2());
        case "-":
          return self.eval_M(obj.e1()) - self.eval_M(obj.e2());
        case "/":
          return self.eval_M(obj.e1()) / self.eval_M(obj.e2());
        case "<":
          return self.eval_M(obj.e1()) < self.eval_M(obj.e2());
        case ">":
          return self.eval_M(obj.e1()) > self.eval_M(obj.e2());
        case "<=":
          return self.eval_M(obj.e1()) <= self.eval_M(obj.e2());
        case ">=":
          return self.eval_M(obj.e1()) >= self.eval_M(obj.e2());
        default:
          return self.raise(Enso.S("Unknown operator (", obj.op().to_s(), ")"));
      }
    };

    eval_EUnOp(obj) {
      var self = this;
      if (obj.op() == "!") {
        return ! self.eval_M(obj.e());
      } else {
        return self.raise(Enso.S("Unknown operator (", obj.op(), ")"));
      }
    };

    eval_EVar(obj) {
      var self = this, env;
      env = self.D$.get$("env");
      if (! env) {
        self.raise("ERROR: environment not defined");
      }
      if (! env.has_key_P(obj.name().to_s())) {
        self.raise(Enso.S("ERROR: undefined variable ", obj.name(), " in ", env));
      }
      return env.get$(obj.name().to_s());
    };

    eval_ESubscript(obj) {
      var self = this;
      return self.eval_M(obj.e()).get$(self.eval_M(obj.sub()));
    };

    eval_EConst(obj) {
      var self = this;
      return obj.val();
    };

    eval_ENil(obj) {
      var self = this;
      return null;
    };

    eval_EFunCall(obj) {
      var self = this, m;
      m = self.dynamic_bind(function() {
        return self.eval_M(obj.fun());
      }, Enso.EMap.new({in_fc: true}));
      return m.call_closure(...obj.params().map(function(p) {
        return self.eval_M(p);
      }));
    };

    eval_EList(obj) {
      var self = this;
      return obj.elems().map(function(elem) {
        return self.eval_M(elem);
      });
    };

    eval_InstanceOf(obj) {
      var self = this, a;
      a = self.eval_M(obj.base());
      return a && Schema.subclass_P(a.schema_class(), obj.class_name());
    };

    eval_EField(obj) {
      var self = this, target, r;
      target = self.dynamic_bind(function() {
        return self.eval_M(obj.e());
      }, Enso.EMap.new({in_fc: false}));
      if (self.D$.get$("in_fc")) {
        return target.method(obj.fname().to_sym());
      } else if (target.respond_to_P(obj.fname())) {
        r = target.send(obj.fname());
        return r;
      } else {
        return self.raise(Enso.S("Can't get ", obj.fname(), " of ", target));
      }
    }; }};

class EvalExprC extends Enso.mix(Enso.EnsoBaseClass, EvalExpr) {
  static new(...args) { return new EvalExprC(...args) };

};

Eval = {
  make_default_const: make_default_const,
  eval_M: eval_M,
  make_const: make_const,
  EvalExpr: EvalExpr,
  EvalExprC: EvalExprC,
};
module.exports = Eval ;
