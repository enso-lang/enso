define([
  "core/expr/code/impl",
  "core/expr/code/env",
  "core/diagram/code/traceval",
  "core/schema/code/factory",
  "core/system/library/schema"
],
function(Impl, Env, Traceval, Factory, Schema) {
  var Evalexprstencil ;
  var EvalExprStencil = MakeMixin([Traceval.TracevalCommand], function() {
    this.eval_Rule = function(obj) {
      var self = this; 
      var funname, forms;
      funname = S(obj.name(), "__", obj.type());
      forms = [obj.obj()];
      obj.formals().each(function(f) {
        return forms.push(f.name());
      });
      self.$.D._get("env")._set(funname, Impl.Closure.make_closure(obj.body(), forms, self.$.D._get("env"), self));
      return self.$.D._get("srctemp")._set(funname, Impl.Closure.new(obj.body(), forms, self.$.D._get("env"), self));
    };

    this.eval_RuleCall = function(obj) {
      var self = this; 
      var target, funname, m, params, clos, newsrctmp, param_src, res;
      target = self.eval(obj.obj());
      funname = S(obj.name(), "__", target.schema_class().name());
      m = self.$.D._get("env")._get(funname);
      params = obj.params().map(function(p) {
        return self.eval(p);
      });
      clos = self.$.D._get("srctemp")._get(funname);
      newsrctmp = self.$.D._get("srctemp").clone();
      clos.formals().each_with_index(function(f, i) {
        if (i == 0) {
          return newsrctmp._set(f, target);
        } else {
          param_src = self.$.D._get("src")._get(obj.params()._get(i - 1));
          return newsrctmp._set(f, param_src);
        }
      });
      res = null;
      self.dynamic_bind(function() {
        return res = m.apply(m, [target].concat(params));
      }, new EnsoHash ({ srctemp: newsrctmp }));
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(clos.body()));
      return res;
    };

    this.eval_EFor = function(obj) {
      var self = this; 
      var env, nenv, res;
      env = new EnsoHash ({ });
      env._set(obj.var(), null);
      nenv = Env.HashEnv.new(env, self.$.D._get("env"));
      res = self.eval(obj.list()).map(function(val) {
        nenv._set(obj.var(), val);
        return self.dynamic_bind(function() {
          return self.eval(obj.body());
        }, new EnsoHash ({ env: nenv }));
      });
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body()));
      return res;
    };

    this.eval_InstanceOf = function(obj) {
      var self = this; 
      var a;
      a = self.eval(obj.base());
      return a && Schema.subclass_P(a.schema_class(), obj.class_name());
    };

    this.eval_Eval = function(obj) {
      var self = this; 
      var env1, expr1, res;
      env1 = Env.HashEnv.new();
      obj.envs().map(function(e) {
        return self.eval(e);
      }).each(function(env) {
        if (System.test_type(env, Factory.List)) {
          return env.each(function(v) {
            return env1._set(v.name(), v);
          });
        } else {
          return env.each_pair(function(k, v) {
            return env1._set(k, v);
          });
        }
      });
      expr1 = self.eval(obj.expr());
      res = self.dynamic_bind(function() {
        return self.eval(expr1);
      }, new EnsoHash ({ env: env1 }));
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(expr1));
      return res;
    };
  });

  Evalexprstencil = {
    EvalExprStencil: EvalExprStencil,

  };
  return Evalexprstencil;
})
