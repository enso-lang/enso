define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter",
  "core/expr/code/env"
],
function(Eval, Lvalue, Interpreter, Env) {

  var Impl ;
  var Closure = MakeClass(null, [],
    function() {
    },
    function(super$) {
      this.env = function() { return this.$.env };
      this.set_env = function(val) { this.$.env  = val };

      this.initialize = function(body, formals, env, interp) {
        var self = this; 
        self.$.body = body;
        self.$.formals = formals;
        self.$.env = env.clone();
        return self.$.interp = interp;
      };

      this.call_closure = function() {
        var self = this; 
        var params = compute_rest_arguments(arguments, 0 );
        var nenv;
        nenv = Env.HashEnv.new();
        self.$.formals.zip(params).each(function(f, v) {
          return nenv._set(f.name(), v);
        });
        nenv.set_parent(self.$.env);
        return self.$.interp.dynamic_bind(function() {
          return self.$.interp.eval(self.$.body);
        }, new EnsoHash ( { env: nenv } ));
      };

      this.to_s = function() {
        var self = this; 
        return S("#<Closure(", self.$.formals.map(function(f) {
          return f.name();
        }).join(", "), ") {", self.$.body, "}>");
      };
    });

  var EvalCommand = MakeMixin([Eval.EvalExpr, Lvalue.LValueExpr, Interpreter.Dispatcher], function() {
    this.eval = function(obj) {
      var self = this; 
      return self.dispatch("eval", obj);
    };

    this.eval_EWhile = function(cond, body) {
      var self = this; 
      while (self.eval(cond)) {
        self.eval(body);
      }
    };

    this.eval_EFor = function(var_V, list, body) {
      var self = this; 
      var nenv;
      nenv = Env.HashEnv.new().set_parent(self.$.D._get("env"));
      return self.eval(list).each(function(val) {
        nenv._set(var_V, val);
        return self.dynamic_bind(function() {
          return self.eval(body);
        }, new EnsoHash ( { env: nenv } ));
      });
    };

    this.eval_EIf = function(cond, body, body2) {
      var self = this; 
      if (self.eval(cond)) {
        return self.eval(body);
      } else if (! (body2 == null)) {
        return self.eval(body2);
      }
    };

    this.eval_EBlock = function(body) {
      var self = this; 
      var res;
      res = null;
      self.dynamic_bind(function() {
        return body.each(function(c) {
          return res = self.eval(c);
        });
      }, new EnsoHash ( { in_fc: false } ));
      return res;
    };

    this.eval_EFunDef = function(name, formals, body) {
      var self = this; 
      var res;
      res = Impl.Closure.new(body, formals, self.$.D._get("env"), self);
      res.env()._set(name, res);
      self.$.D._get("env")._set(name, res);
      return res;
    };

    this.eval_ELambda = function(body, formals) {
      var self = this; 
      return Proc.new(function() {
        var p = compute_rest_arguments(arguments, 0 );
        return Impl.Closure.new(body, formals, self.$.D._get("env"), self).call_closure.apply(Impl.Closure.new(body, formals, self.$.D._get("env"), self), [].concat( p ));
      });
    };

    this.eval_EFunCall = function(fun, params, lambda) {
      var self = this; 
      var m, p;
      m = self.dynamic_bind(function() {
        return self.eval(fun);
      }, new EnsoHash ( { in_fc: true } ));
      if (lambda == null) {
        puts(S("params = ", params.map(function(p) {
          return self.eval(p);
        })));
        return m.apply(m, [].concat( params.map(function(p) {
          return self.eval(p);
        }) ));
      } else {
        p = self.eval(lambda);
        return m.apply(m, [p].concat( params.map(function(p) {
          return self.eval(p);
        }) ));
      }
    };

    this.eval_EAssign = function(var_V, val) {
      var self = this; 
      return self.lvalue(var_V).value = self.eval(val);
    };
  });

  var EvalCommandC = MakeClass(null, [EvalCommand],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Impl = {
    Closure: Closure,
    EvalCommand: EvalCommand,
    EvalCommandC: EvalCommandC,

  };
  return Impl;
})
