define([
  "core/system/library/schema",
  "core/semantics/code/interpreter"
],
function(Schema, Interpreter) {
  var Eval ;

  var EvalExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.eval = function(obj) {
      var self = this; 
      return self.dispatch_obj("eval", obj);
    };

    this.eval_ETernOp = function(obj) {
      var self = this; 
      if (self.eval(obj.e1())) {
        return self.eval(obj.e2());
      } else {
        return self.eval(obj.e3());
      }
    };

    this.eval_EBinOp = function(obj) {
      var self = this; 
      switch (obj.op()) {
        case "&":
          return self.eval(obj.e1()) && self.eval(obj.e2());
        case "|":
          return self.eval(obj.e1()) || self.eval(obj.e2());
        case "eql?":
          return self.eval(obj.e1()) == self.eval(obj.e2());
        case "+":
          return self.eval(obj.e1()) + self.eval(obj.e2());
        case "*":
          return self.eval(obj.e1()) * self.eval(obj.e2());
        case "-":
          return self.eval(obj.e1()) - self.eval(obj.e2());
        case "/":
          return self.eval(obj.e1()) / self.eval(obj.e2());
        case "<":
          return self.eval(obj.e1()) < self.eval(obj.e2());
        case ">":
          return self.eval(obj.e1()) > self.eval(obj.e2());
        case "<=":
          return self.eval(obj.e1()) <= self.eval(obj.e2());
        case ">=":
          return self.eval(obj.e1()) >= self.eval(obj.e2());
        default:
          return self.raise(S("Unknown operator (", obj.op(), ")"));
      }
    };

    this.eval_EUnOp = function(obj) {
      var self = this; 
      if (obj.op() == "!") {
        return ! self.eval(obj.e());
      } else {
        return self.raise(S("Unknown operator (", obj.op(), ")"));
      }
    };

    this.eval_EVar = function(obj) {
      var self = this; 
      if (! self.$.D._get("env").has_key_P(obj.name())) {
        self.raise(S("ERROR: undefined variable ", obj.name(), " in ", self.$.D._get("env")));
      }
      return self.$.D._get("env")._get(obj.name());
    };

    this.eval_ESubscript = function(obj) {
      var self = this; 
      return self.eval(obj.e())._get(self.eval(obj.sub()));
    };

    this.eval_EConst = function(obj) {
      var self = this; 
      return obj.val();
    };

    this.eval_ENil = function() {
      var self = this; 
      return null;
    };

    this.eval_EFunCall = function(obj) {
      var self = this; 
      var m;
      m = self.dynamic_bind(function() {
        return self.eval(obj.fun());
      }, new EnsoHash ({ in_fc: true }));
      return m.call_closure.apply(m, [].concat(obj.params().map(function(p) {
        return self.eval(p);
      })));
    };

    this.eval_EList = function(obj) {
      var self = this; 
      return obj.elems().map(function(elem) {
        return self.eval(elem);
      });
    };

    this.eval_EField = function(obj) {
      var self = this; 
      var target;
      target = self.dynamic_bind(function() {
        return self.eval(obj.e());
      }, new EnsoHash ({ in_fc: false }));
      if (self.$.D._get("in_fc")) {
        return target.method(obj.fname().to_sym());
      } else {
        return target.send(obj.fname());
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
    make_const: function(factory, val) {
      var self = this; 
      if (System.test_type(val, String)) {
        return factory.EStrConst(val);
      } else if (System.test_type(val, Integer) && val % 1 == 0) {
        return factory.EIntConst(val);
      } else if (System.test_type(val, Float) && val % 1 != 0) {
        return factory.ERealConst(val);
      } else if (System.test_type(val, TrueClass) || System.test_type(val, FalseClass)) {
        return factory.EBoolConst(val);
      } else if (val == null) {
        return factory.ENil();
      } else {
        return val;
      }
    },

    eval: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = EvalExprC.new();
      return interp.dynamic_bind(function() {
        return interp.eval(obj);
      }, args);
    },

    EvalExpr: EvalExpr,
    EvalExprC: EvalExprC,

  };
  return Eval;
})
