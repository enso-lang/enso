define(["core/expr/code/eval", "core/expr/code/lvalue", "core/semantics/code/interpreter", "core/expr/code/env"], (function (Eval, Lvalue, Interpreter, Env) {
  var Impl;
  var Closure = MakeClass("Closure", null, [], (function () {
    (this.make_closure = (function (body, formals, env, interp) {
      var self = this;
      return Closure.new(body, formals, env, interp).method("call_closure");
    }));
  }), (function (super$) {
    (this.formals = (function () {
      return this.$.formals;
    }));
    (this.body = (function () {
      return this.$.body;
    }));
    (this.initialize = (function (body, formals, env, interp) {
      var self = this;
      (self.$.body = body);
      (self.$.formals = formals);
      (self.$.env = env);
      return (self.$.interp = interp);
    }));
    (this.call_closure = (function () {
      var self = this;
      var params = compute_rest_arguments(arguments, this.call_closure.length);
      var nv, nenv;
      (nv = (new EnsoHash({
        
      })));
      self.$.formals.each_with_index((function (f, i) {
        return nv._set(f, params._get(i));
      }));
      (nenv = Env.HashEnv.new(nv, self.$.env));
      return self.$.interp.dynamic_bind((function () {
        return self.$.interp.eval(self.$.body);
      }), (new EnsoHash({
        env: nenv
      })));
    }));
    (this.to_s = (function () {
      var self = this;
      return S("#<Closure(", self.$.formals.map((function (f) {
        return f.name();
      })).join(", "), ") {", self.$.body, "}>");
    }));
  }));
  var EvalCommand = MakeMixin([Eval.EvalExpr, Lvalue.LValueExpr, Interpreter.Dispatcher], (function () {
    (this.eval = (function (obj) {
      var self = this;
      return self.dispatch_obj("eval", obj);
    }));
    (this.eval_EWhile = (function (obj) {
      var self = this;
      while (self.eval(obj.cond())) self.eval(obj.body());
    }));
    (this.eval_EFor = (function (obj) {
      var self = this;
      var env, nenv;
      (env = (new EnsoHash({
        
      })));
      env._set(obj.var(), null);
      (nenv = Env.HashEnv.new(env, self.$.D._get("env")));
      return self.eval(obj.list()).each((function (val) {
        nenv._set(obj.var(), val);
        return self.dynamic_bind((function () {
          return self.eval(obj.body());
        }), (new EnsoHash({
          env: nenv
        })));
      }));
    }));
    (this.eval_EIf = (function (obj) {
      var self = this;
      if (self.eval(obj.cond())) { 
        return self.eval(obj.body()); 
      }
      else { 
        if ((!(obj.body2() == null))) { 
          return self.eval(obj.body2()); 
        } 
        else {
             }
      }
    }));
    (this.eval_EBlock = (function (obj) {
      var self = this;
      var res, env1, defenv;
      (res = null);
      (defenv = Env.HashEnv.new((new EnsoHash({
        
      })), self.$.D._get("env")));
      self.dynamic_bind((function () {
        return obj.fundefs().each((function (c) {
          return self.eval(c);
        }));
      }), (new EnsoHash({
        in_fc: false,
        env: defenv
      })));
      (env1 = Env.HashEnv.new((new EnsoHash({
        
      })), defenv));
      self.dynamic_bind((function () {
        return obj.body().each((function (c) {
          return (res = self.eval(c));
        }));
      }), (new EnsoHash({
        in_fc: false,
        env: env1
      })));
      return res;
    }));
    (this.eval_EFunDef = (function (obj) {
      var self = this;
      var forms;
      (forms = []);
      obj.formals().each((function (f) {
        return forms.push(f.name());
      }));
      self.$.D._get("env")._set(obj.name(), Impl.Closure.make_closure(obj.body(), forms, self.$.D._get("env"), self));
      return null;
    }));
    (this.eval_ELambda = (function (obj) {
      var self = this;
      var forms;
      (forms = []);
      obj.formals().each((function (f) {
        return forms.push(f.name());
      }));
      return Proc.new((function () {
        var p = compute_rest_arguments(arguments, 0);
        return Impl.Closure.make_closure(obj.body(), forms, self.$.D._get("env"), self).apply(Impl.Closure.make_closure(obj.body(), forms, self.$.D._get("env"), self), [].concat(p));
      }));
    }));
    (this.eval_EFunCall = (function (obj) {
      var self = this;
      var b, m;
      (m = self.dynamic_bind((function () {
        return self.eval(obj.fun());
      }), (new EnsoHash({
        in_fc: true
      }))));
      if ((obj.lambda() == null)) { 
        return m.apply(m, [].concat(obj.params().map((function (p) {
          return self.eval(p);
        })))); 
      } 
      else {
             (b = self.eval(obj.lambda()));
             return m.apply(m, [b].concat(obj.params().map((function (p) {
               return self.eval(p);
             }))));
           }
    }));
    (this.eval_EAssign = (function (obj) {
      var self = this;
      return self.lvalue(obj.var()).set_value(self.eval(obj.val()));
    }));
  }));
  var EvalCommandC = MakeClass("EvalCommandC", null, [EvalCommand], (function () {
  }), (function (super$) {
    (this.initialize = (function () {
      var self = this;
    }));
  }));
  (Impl = {
    EvalCommand: EvalCommand,
    EvalCommandC: EvalCommandC,
    Closure: Closure,
    eval: (function (obj, args) {
      var self = this;
      (args = (((typeof args) !== "undefined") ? args : (new EnsoHash({
        env: (new EnsoHash({
          
        }))
      }))));
      var interp;
      (interp = EvalCommandC.new());
      return interp.dynamic_bind((function () {
        return interp.eval(obj);
      }), args);
    })
  });
  return Impl;
}));