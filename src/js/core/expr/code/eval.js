define([
  "core/schema/code/factory",
  "core/system/library/schema",
  "core/semantics/code/interpreter"
],
function(Factory, Schema, Interpreter) {
  var Eval ;

  var EvalExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.eval = function(obj) {
      self.debug();
      var self = this; 
      return self.dispatch("eval", obj);
    };

    this.eval_ETernOp = function(op1, op2, e1, e2, e3) {
      var self = this; 
      if (self.eval(e1)) {
        return self.eval(e2);
      } else {
        return self.eval(e3);
      }
    };

    this.eval_EBinOp = function(op, e1, e2) {
      var self = this; 
      switch (op) {
        case "&":
          return self.eval(e1) && self.eval(e2);
        case "|":
          return self.eval(e1) || self.eval(e2);
        case "eql?":
          return self.eval(e1) == self.eval(e2);
        case "+":
          return self.eval(e1) + self.eval(e2);
        case "*":
          return self.eval(e1) * self.eval(e2);
        case "-":
          return self.eval(e1) - self.eval(e2);
        case "/":
          return self.eval(e1) / self.eval(e2);
        case "<":
          return self.eval(e1) < self.eval(e2);
        case ">":
          return self.eval(e1) > self.eval(e2);
        case "<=":
          return self.eval(e1) <= self.eval(e2);
        case ">=":
          return self.eval(e1) >= self.eval(e2);
        default:
          return self.raise(S("Unknown operator (", op, ")"));
      }
    };

    this.eval_EUnOp = function(op, e) {
      var self = this; 
      if (op == "!") {
        return ! self.eval(e);
      } else {
        return self.raise(S("Unknown operator (", op, ")"));
      }
    };

    this.eval_EVar = function(name) {
      var self = this; 
      if (! self.$.D._get("env").has_key_P(name)) {
        self.raise(S("ERROR: undefined variable ", name, " in ", self.$.D._get("env")));
      }
      return self.$.D._get("env")._get(name);
    };

    this.eval_ESubscript = function(e, sub) {
      var self = this; 
      return self.eval(e)._get(self.eval(sub));
    };

    this.eval_EConst = function(val) {
      var self = this; 
      return val;
    };

    this.eval_ENil = function() {
      var self = this; 
      return null;
    };

    this.eval_EFunCall = function(fun, params) {
      var self = this; 
      var m;
      m = self.dynamic_bind(function() {
        return self.eval(fun);
      }, new EnsoHash ({ in_fc: true }));
      return m.call_closure.apply(m, [].concat(params.map(function(p) {
        return self.eval(p);
      })));
    };

    this.eval_EList = function(elems) {
      var self = this; 
      return elems.map(function(elem) {
        return self.eval(elem);
      });
    };

    this.eval_EField = function(e, fname) {
      var self = this; 
      var target;
      target = self.dynamic_bind(function() {
        return self.eval(e);
      }, new EnsoHash ({ in_fc: false }));
      if (self.$.D._get("in_fc")) {
        return target.method(fname.to_sym());
      } else {
        return target.send(fname);
      }
    };
  });

  var EvalExprC = MakeClass("EvalExprC", null, [EvalExpr],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Eval = {
    eval: function(obj) {
      var self = this; 
      var args = compute_rest_arguments(arguments, 1);
      var interp;
      interp = EvalExprC.new();
      if (args.empty_P()) {
        return interp.eval(obj);
      } else {
        return interp.dynamic_bind(function() {
          return interp.eval(obj);
        });
      }
    },

    make_const: function(factory, val) {
      var self = this; 
      if (System.test_type(val, String)) {
        return factory.EStrConst(val);
      } else if (System.test_type(val, Integer)) {
        return factory.EIntConst(val);
      } else if (System.test_type(val, TrueClass) || System.test_type(val, FalseClass)) {
        return factory.EBoolConst(val);
      } else if (val == null) {
        return factory.ENil();
      } else if (System.test_type(val, Factory.MObject)) {
        return val;
      } else {
        return Eval.raise(S("Trying to make constant using an invalid ", val.class(), " object"));
      }
    },

    EvalExpr: EvalExpr,
    EvalExprC: EvalExprC,

  };
  return Eval;
})
