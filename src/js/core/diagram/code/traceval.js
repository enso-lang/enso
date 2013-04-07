define([
  "core/schema/code/factory",
  "core/semantics/code/interpreter",
  "core/expr/code/env",
  "core/expr/code/impl",
  "core/expr/code/eval",
  "core/schema/tools/union"
],
function(Factory, Interpreter, Env, Impl, Eval, Union) {
  var Traceval ;

  var TracevalCommand = MakeMixin([Interpreter.Dispatcher, Impl.EvalCommand], function() {
    this.eval_ETernOp = function(obj) {
      var self = this; 
      var e1, e2, e3, res, src;
      e1 = self.eval(obj.e1());
      e2 = self.eval(obj.e2());
      e3 = self.eval(obj.e3());
      res = e1
        ? e2
        : e3;
      src = self.$.D._get("factory")._get(obj.schema_class().name());
      src.set_e1(self.$.D._get("src")._get(obj.e1()));
      src.set_e2(self.$.D._get("src")._get(obj.e2()));
      src.set_e3(self.$.D._get("src")._get(obj.e3()));
      self.$.D._get("src")._set(obj, src);
      return res;
    };

    this.eval_EBinOp = function(obj) {
      var self = this; 
      var res, src;
      res = null;
      switch (obj.op()) {
        case "&":
          res = self.eval(obj.e1()) && self.eval(obj.e2());
          break;
        case "|":
          res = self.eval(obj.e1()) || self.eval(obj.e2());
          break;
        case "eql?":
          res = self.eval(obj.e1()) == self.eval(obj.e2());
          break;
        case "+":
          res = self.eval(obj.e1()) + self.eval(obj.e2());
          break;
        case "*":
          res = self.eval(obj.e1()) * self.eval(obj.e2());
          break;
        case "-":
          res = self.eval(obj.e1()) - self.eval(obj.e2());
          break;
        case "/":
          res = self.eval(obj.e1()) / self.eval(obj.e2());
          break;
        case "<":
          res = self.eval(obj.e1()) < self.eval(obj.e2());
          break;
        case ">":
          res = self.eval(obj.e1()) > self.eval(obj.e2());
          break;
        case "<=":
          res = self.eval(obj.e1()) <= self.eval(obj.e2());
          break;
        case ">=":
          res = self.eval(obj.e1()) >= self.eval(obj.e2());
          break;
        default:
          self.raise(S("Unknown operator (", obj.op(), ")"));
          break;
      }
      src = self.$.D._get("factory")._get(obj.schema_class().name());
      src.set_op(obj.op());
      src.set_e1(self.$.D._get("src")._get(obj.e1()));
      src.set_e2(self.$.D._get("src")._get(obj.e2()));
      self.$.D._get("src")._set(obj, src);
      return res;
    };

    this.eval_EUnOp = function(obj) {
      var self = this; 
      var res, src;
      res = obj.op() == "!"
        ? ! self.eval(obj.e())
        : self.raise(S("Unknown operator (", obj.op(), ")"));
      src = self.$.D._get("factory")._get(obj.schema_class().name());
      src.set_op(obj.op());
      src.set_e(self.$.D._get("src")._get(obj.e()));
      self.$.D._get("src")._set(obj, src);
      return res;
    };

    this.eval_EVar = function(obj) {
      var self = this; 
      var res, path;
      if (! self.$.D._get("env").has_key_P(obj.name())) {
        self.raise(S("ERROR: undefined variable ", obj.name(), " in ", self.$.D._get("env")));
      }
      res = self.$.D._get("env")._get(obj.name());
      if (! System.test_type(res, Factory.MObject)) {
        if (self.$.D._get("srctemp")._get(obj.name())) {
          self.$.D._get("src")._set(obj, self.$.D._get("srctemp")._get(obj.name()));
        } else {
          self.$.D._get("src")._set(obj, Eval.make_const(self.$.D._get("factory"), res));
        }
      } else {
        path = Union.Copy(self.$.D._get("factory"), res._path().path());
        self.$.D._get("src")._set(obj, path);
      }
      return res;
    };

    this.eval_EConst = function(obj) {
      var self = this; 
      var res;
      res = obj.val();
      self.$.D._get("src")._set(obj, Eval.make_const(self.$.D._get("factory"), res));
      return res;
    };

    this.eval_ENil = function(obj) {
      var self = this; 
      self.$.D._get("src")._set(obj, self.$.D._get("factory").ENil());
      return null;
    };

    this.eval_EField = function(obj) {
      var self = this; 
      var target, res, src;
      target = self.dynamic_bind(function() {
        return self.eval(obj.e());
      }, new EnsoHash ({ in_fc: false }));
      res = self.$.D._get("in_fc")
        ? target.method(obj.fname().to_sym())
        : target.send(obj.fname());
      src = self.$.D._get("factory")._get(obj.schema_class().name());
      src.set_fname(obj.fname());
      src.set_e(self.$.D._get("src")._get(obj.e()));
      self.$.D._get("src")._set(obj, src);
      return res;
    };

    this.eval_EFunCall = function(obj) {
      var self = this; 
      var m, params, clos, newsrctmp, param_src, res, b;
      m = self.dynamic_bind(function() {
        return self.eval(obj.fun());
      }, new EnsoHash ({ in_fc: true }));
      params = obj.params().map(function(p) {
        return self.eval(p);
      });
      if (obj.fun().EVar_P() && self.$.D._get("srctemp")._get(obj.fun().name()) != null) {
        clos = self.$.D._get("srctemp")._get(obj.fun().name());
        newsrctmp = self.$.D._get("srctemp").clone();
        clos.formals().each_with_index(function(f, i) {
          param_src = self.$.D._get("src")._get(obj.params()._get(i));
          return newsrctmp._set(f, param_src);
        });
        res = null;
        if (obj.lambda() == null) {
          self.dynamic_bind(function() {
            return res = m.apply(m, [].concat(params));
          }, new EnsoHash ({ srctemp: newsrctmp }));
        } else {
          b = self.eval(obj.lambda());
          self.dynamic_bind(function() {
            return res = m.apply(m, [b].concat(params));
          }, new EnsoHash ({ srctemp: newsrctmp }));
        }
        self.$.D._get("src")._set(obj, self.$.D._get("src")._get(clos.body()));
        return res;
      } else {
        if (obj.lambda() == null) {
          res = m.apply(m, [].concat(params));
        } else {
          b = self.eval(obj.lambda());
          res = m.apply(m, [b].concat(params));
        }
        self.$.D._get("src")._set(obj, Eval.make_const(self.$.D._get("factory"), res));
        return res;
      }
    };

    this.eval_EBlock = function(obj) {
      var self = this; 
      var res, defenv, env1, last;
      res = null;
      defenv = Env.HashEnv.new(new EnsoHash ({ }), self.$.D._get("env"));
      self.dynamic_bind(function() {
        return obj.fundefs().each(function(c) {
          return self.eval(c);
        });
      }, new EnsoHash ({ in_fc: false, env: defenv }));
      env1 = Env.HashEnv.new(new EnsoHash ({ }), defenv);
      self.dynamic_bind(function() {
        return obj.body().each(function(c) {
          return res = self.eval(c);
        });
      }, new EnsoHash ({ in_fc: false, env: env1 }));
      last = obj.body()._get(obj.body().size() - 1);
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(last));
      return res;
    };

    this.eval_EWhile = function(obj) {
      var self = this; 
      var res;
      res = ((function() {
        while (self.eval(obj.cond())) {
          self.eval(obj.body());
        }
      })());
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body()));
      return res;
    };

    this.eval_EFor = function(obj) {
      var self = this; 
      var nenv, res;
      nenv = Env.HashEnv.new(new EnsoHash ({ }), self.$.D._get("env"));
      res = self.eval(obj.list()).each(function(val) {
        nenv._set(obj.var(), val);
        return self.dynamic_bind(function() {
          return self.eval(obj.body());
        }, new EnsoHash ({ env: nenv }));
      });
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body()));
      return res;
    };

    this.eval_EIf = function(obj) {
      var self = this; 
      var res;
      if (self.eval(obj.cond())) {
        res = self.eval(obj.body());
        self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body()));
        return res;
      } else if (! (obj.body2() == null)) {
        res = self.eval(obj.body2());
        self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body2()));
        return res;
      }
    };

    this.eval_EFunDef = function(obj) {
      var self = this; 
      var forms;
      forms = [];
      obj.formals().each(function(f) {
        return forms.push(f.name());
      });
      self.$.D._get("env")._set(obj.name(), Impl.Closure.make_closure(obj.body(), forms, self.$.D._get("env"), self));
      self.$.D._get("srctemp")._set(obj.name(), Impl.Closure.new(obj.body(), forms, self.$.D._get("env"), self));
      return null;
    };

    this.eval_EAssign = function(obj) {
      var self = this; 
      self.lvalue(obj.var()).set_value(self.eval(obj.val()));
      if (obj.var().EVar_P()) {
        return self.$.D._get("srctemp")._set(obj.var().name(), self.$.D._get("src")._get(obj.val()));
      }
    };
  });

  var TracevalCommandC = MakeClass("TracevalCommandC", null, [TracevalCommand],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Traceval = {
    eval: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = TracevalCommandC.new();
      return interp.dynamic_bind(function() {
        return interp.eval(obj);
      }, args);
    },

    TracevalCommand: TracevalCommand,
    TracevalCommandC: TracevalCommandC,

  };
  return Traceval;
})
