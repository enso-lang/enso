define([
  "core/schema/code/factory",
  "core/system/library/schema",
  "core/semantics/code/interpreter"
],
function(Factory, Schema, Interpreter) {

  var Eval ;
  var EvalExpr = MakeMixin({
    include: [ Interpreter. Dispatcher ],

    eval: function(obj) {
      var self = this; 
      var super$ = this.super$.eval;
      return self.dispatch("eval", obj);
    },

    eval_ETernOp: function(op1, op2, e1, e2, e3) {
      var self = this; 
      var super$ = this.super$.eval_ETernOp;
      if (self.eval(e1)) {
        return self.eval(e2);
      } else {
        return self.eval(e3);
      }
    },

    eval_EBinOp: function(op, e1, e2) {
      var self = this; 
      var super$ = this.super$.eval_EBinOp;
      if (op == "&") {
        return self.eval(e1) && self.eval(e2);
      } else if (op == "|") {
        return self.eval(e1) || self.eval(e2);
      } else {
        return self.eval(e1).send(op.to_s(), self.eval(e2));
      }
    },

    eval_EUnOp: function(op, e) {
      var self = this; 
      var super$ = this.super$.eval_EUnOp;
      return self.eval(e).send(op.to_s());
    },

    eval_EVar: function(name) {
      var self = this; 
      var super$ = this.super$.eval_EVar;
      if (! self.$.D._get("env").has_key_P(name)) {
        self.raise(S("ERROR: undefined variable ", name));
      }
      return self.$.D._get("env")._get(name);
    },

    eval_ESubscript: function(e, sub) {
      var self = this; 
      var super$ = this.super$.eval_ESubscript;
      return self.eval(e)._get(self.eval(sub));
    },

    eval_EConst: function(val) {
      var self = this; 
      var super$ = this.super$.eval_EConst;
      return val;
    },

    eval_ENil: function() {
      var self = this; 
      var super$ = this.super$.eval_ENil;
      return null;
    },

    eval_EFunCall: function(fun, params) {
      var self = this; 
      var super$ = this.super$.eval_EFunCall;
      return self.dynamic_bind(function() {
        return self.eval(fun).call .call_rest_args$(self.eval(fun), params.map(function(p) {
          return self.eval(p);
        }) );
      }, new EnsoHash ( { } ));
    },

    eval_EList: function(elems) {
      var self = this; 
      var k, r;
      var super$ = this.super$.eval_EList;
      k = Schema.class_key(self.$.D._get("for_field").type());
      if (k) {
        r = Factory.Set().new(null, null, k);
      } else {
        r = Factory.List().new(null, null);
      }
      elems.each(function(elem) {
        return r.push(self.eval(elem));
      });
      return r;
    },

    eval_EField: function(e, fname) {
      var self = this; 
      var target;
      var super$ = this.super$.eval_EField;
      if (self.$.D._get("in_fc")) {
        return self.dynamic_bind(function() {
          target = self.eval(e);
          return target.method(fname.to_sym());
        }, new EnsoHash ( { } ));
      } else {
        return self.eval(e).send(fname);
      }
    }
  });

  var EvalExprC = MakeClass( {
    include: [ EvalExpr ],

    initialize: function() {
      var self = this; 
      var super$ = this.super$.initialize;
    }
  });

  Eval = {
    EvalExpr: EvalExpr,
    EvalExprC: EvalExprC,

  };
  return Eval;
})
