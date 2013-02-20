define([
  "core/schema/code/factory",
  "core/system/library/schema",
  "core/semantics/code/interpreter"
],
function(Factory, Schema, Interpreter) {

  var Eval ;
  var EvalExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.eval = function(obj) {
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
      if (op == "&") {
        return self.eval(e1) && self.eval(e2);
      } else if (op == "|") {
        return self.eval(e1) || self.eval(e2);
      } else {
        return self.eval(e1).send(op.to_s(), self.eval(e2));
      }
    };

    this.eval_EUnOp = function(op, e) {
      var self = this; 
      return self.eval(e).send(op.to_s());
    };

    this.eval_EVar = function(name) {
      var self = this; 
      if (! self.$.D._get("env").has_key_P(name)) {
        self.raise(S("ERROR: undefined variable ", name));
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
      }, new EnsoHash ( { in_fc: true } ));
      return m.call_closure.apply(m, [].concat( params.map(function(p) {
        return self.eval(p);
      }) ));
    };

    this.eval_EList = function(elems) {
      var self = this; 
      var k, r;
      k = Schema.class_key(self.$.D._get("for_field").type());
      if (k) {
        r = Factory.Set.new(null, null, k);
      } else {
        r = Factory.List.new(null, null);
      }
      elems.each(function(elem) {
        return r.push(self.eval(elem));
      });
      return r;
    };

    this.eval_EField = function(e, fname) {
      var self = this; 
      var target;
      if (self.$.D._get("in_fc")) {
        return self.dynamic_bind(function() {
          target = self.eval(e);
          try {
            Print.print(target);
          } catch ( DUMMY ) {
          }
          return target.method(fname.to_sym());
        }, new EnsoHash ( { in_fc: false } ));
      } else {
        return self.eval(e).send(fname);
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
    EvalExpr: EvalExpr,
    EvalExprC: EvalExprC,

  };
  return Eval;
})
