define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter",
  "core/expr/code/env"
],
function(Eval, Lvalue, Interpreter, Env) {
  var Impl ;

  var Closure = MakeClass("Closure", null, [],
    function() {
      this.make_closure = function(body, formals, env, interp) {
        var self = this; 
        return Closure.new(body, formals, env, interp).method("call_closure");
      };
    },
    function(super$) {
      this.env = function() { return this.$.env };
      this.set_env = function(val) { this.$.env  = val };

      this.initialize = function(body, formals, env, interp) {
        var self = this; 
        self.$.body = body;
        self.$.formals = formals;
        self.$.env = env;
        return self.$.interp = interp;
      };

      this.call_closure = function() {
        var self = this; 
        var params = compute_rest_arguments(arguments, 0);
        var nv, nenv;
        nv = new EnsoHash ({ });
        self.$.formals.each_with_index(function(f, i) {
          return nv._set(f.name(), params._get(i));
        });
        nenv = Env.HashEnv.new(nv, self.$.env);
        return self.$.interp.dynamic_bind(function() {
          return self.$.interp.eval(self.$.body);
        }, new EnsoHash ({ env: nenv }));
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
      nenv = Env.HashEnv.new(new EnsoHash ({ }), self.$.D._get("env"));
      return self.eval(list).each(function(val) {
        nenv._set(var_V, val);
        return self.dynamic_bind(function() {
          return self.eval(body);
        }, new EnsoHash ({ env: nenv }));
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

    this.eval_EBlock = function(fundefs, body) {
      var self = this; 
      var res, defenv, env1;
      res = null;
      defenv = Env.HashEnv.new(self.$.D._get("env"));
      self.dynamic_bind(function() {
        return fundefs.each(function(c) {
          return self.eval(c);
        });
      }, new EnsoHash ({ in_fc: false, env: defenv }));
      env1 = Env.HashEnv.new(defenv);
      self.dynamic_bind(function() {
        return body.each(function(c) {
          return res = self.eval(c);
        });
      }, new EnsoHash ({ in_fc: false, env: env1 }));
      return res;
    };

    this.eval_EFunDef = function(name, formals, body) {
      var self = this; 
      self.$.D._get("env")._set(name, Impl.Closure.make_closure(body, formals, self.$.D._get("env"), self));
      return null;
    };

    this.eval_ELambda = function(body, formals) {
      var self = this; 
      return Proc.new(function() {
        var p = compute_rest_arguments(arguments, 0);
        return Impl.Closure.make_closure(body, formals, self.$.D._get("env"), self).apply(Impl.Closure.make_closure(body, formals, self.$.D._get("env"), self), [].concat(p));
      });
    };

    this.eval_EFunCall = function(fun, params, lambda) {
      var self = this; 
      var m, b;
      m = self.dynamic_bind(function() {
        return self.eval(fun);
      }, new EnsoHash ({ in_fc: true }));
      if (lambda == null) {
        return m.apply(m, [].concat(params.map(function(p) {
          return self.eval(p);
        })));
      } else {
        b = self.eval(lambda);
        return m.apply(m, [b].concat(params.map(function(p) {
          return self.eval(p);
        })));
      }
    };

    this.eval_EAssign = function(var_V, val) {
      var self = this; 
      return self.lvalue(var_V).set_value(self.eval(val));
    };
  });

  var EvalCommandC = MakeClass("EvalCommandC", null, [EvalCommand],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Impl = {
    eval: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = EvalCommandC.new();
      if (args.empty_P()) {
        return interp.eval(obj);
      } else {
        return interp.dynamic_bind(function() {
          return interp.eval(obj);
        }, args);
      }
    },

    Closure: Closure,
    EvalCommand: EvalCommand,
    EvalCommandC: EvalCommandC,

  };
  return Impl;
})
