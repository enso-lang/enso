define([
  "core/expr/code/eval",
  "core/expr/code/renderexp",
  "core/semantics/code/interpreter",
  "core/expr/code/impl",
  "core/expr/code/env",
  "core/schema/code/factory",
  "core/system/load/load",
  "core/system/library/schema",
  "core/schema/tools/union"
],
function(Eval, Renderexp, Interpreter, Impl, Env, Factory, Load, Schema, Union) {
  var Construct ;

  var EvalStencil = MakeMixin([Impl.EvalCommand], function() {
    this.eval_Stencil = function(obj) {
      var self = this; 
      var factory, res, env;
      factory = Factory.SchemaFactory.new(Load.load("diagram.schema"));
      res = factory.Stencil(obj.title(), obj.root());
      env = new EnsoHash ({ });
      env._set("data", self.$.D._get("data"));
      self.dynamic_bind(function() {
        return res.set_body(self.eval(obj.body()));
      }, new EnsoHash ({ env: env, factory: factory, props: new EnsoHash ({ }) }));
      return res;
    };

    this.handle_props = function(props) {
      var self = this; 
      var nprops, p1, name;
      nprops = self.$.D._get("props").clone();
      props.each(function(p) {
        p1 = self.eval(p);
        name = Renderexp.render(p1.var());
        return nprops._set(name, p1);
      });
      return nprops;
    };

    this.eval__P = function(obj) {
      var self = this; 
      var type, factory, res, nprops, ev;
      type = obj.schema_class();
      factory = self.$.D._get("factory");
      res = factory._get(type.name());
      nprops = self.handle_props(obj.props());
      nprops.values().each(function(p) {
        return res.props().push(p);
      });
      type.fields().each(function(f) {
        if (! (f.name() == "label" || f.name() == "props")) {
          if (f.type().Primitive_P()) {
            return res._set(f.name(), obj._get(f.name()));
          } else if (f.type().name() == "Expr") {
            if (obj._get(f.name()) == null) {
              return res._set(f.name(), null);
            } else {
              return res._set(f.name(), Eval.make_const(factory, self.eval(obj._get(f.name()))));
            }
          } else if (! f.many()) {
            return self.dynamic_bind(function() {
              return res._set(f.name(), self.eval(obj._get(f.name())));
            }, new EnsoHash ({ props: nprops }));
          } else {
            return obj._get(f.name()).each(function(item) {
              return self.dynamic_bind(function() {
                ev = self.eval(item);
                if (System.test_type(ev, Array)) {
                  return ev.each(function(e) {
                    if (! (e == null)) {
                      return res._get(f.name()).push(e);
                    }
                  });
                } else if (! (ev == null)) {
                  return res._get(f.name()).push(ev);
                }
              }, new EnsoHash ({ props: nprops }));
            });
          }
        }
      });
      if (! (obj.label() == null)) {
        self.$.D._get("env")._set(obj.label(), res);
      }
      return res;
    };

    this.eval_Prop = function(obj) {
      var self = this; 
      var factory, res;
      factory = self.$.D._get("factory");
      res = factory.Prop();
      res.set_var(factory.EStrConst(Renderexp.RenderExprC.new().render(obj.var())));
      res.set_val(Eval.make_const(factory, self.eval(obj.val())));
      return res;
    };

    this.eval_EFor = function(obj) {
      var self = this; 
      var nenv;
      nenv = Env.HashEnv.new(new EnsoHash ({ }), self.$.D._get("env"));
      return self.eval(obj.list()).map(function(val) {
        nenv._set(obj.var(), val);
        return self.dynamic_bind(function() {
          return self.eval(obj.body());
        }, new EnsoHash ({ env: nenv }));
      });
    };

    this.eval_Pages = function(obj) {
      var self = this; 
      var factory, res, nprops, ev, neval;
      factory = self.$.D._get("factory");
      res = factory.Pages();
      nprops = self.handle_props(obj.props());
      nprops.values().each(function(p) {
        return res.props().push(p);
      });
      obj.items().each(function(item) {
        return self.dynamic_bind(function() {
          ev = self.eval(item);
          if (System.test_type(ev, Array)) {
            return ev.flatten().each(function(e) {
              if (! (e == null)) {
                return res.items().push(e);
              }
            });
          } else if (! (ev == null)) {
            return res.items().push(ev);
          }
        }, new EnsoHash ({ props: nprops }));
      });
      if (obj.current().Eval_P()) {
        neval = factory.Eval();
        res.set_current(neval);
      } else {
        res.set_current(Union.Copy(factory, obj.current()));
      }
      if (! (obj.label() == null)) {
        self.$.D._get("env")._set(obj.label(), res);
      }
      return res;
    };

    this.eval_Color = function(obj) {
      var self = this; 
      var factory, r1, g1, b1;
      factory = self.$.D._get("factory");
      r1 = Eval.make_const(factory, Math.round(self.eval(obj.r())));
      g1 = Eval.make_const(factory, Math.round(self.eval(obj.g())));
      b1 = Eval.make_const(factory, Math.round(self.eval(obj.b())));
      return factory.Color(r1, g1, b1);
    };

    this.eval_InstanceOf = function(obj) {
      var self = this; 
      var a;
      a = self.eval(obj.base());
      return a && Schema.subclass_P(a.schema_class(), obj.class_name());
    };

    this.eval_Eval = function(obj) {
      var self = this; 
      var env1, expr1;
      env1 = Env.HashEnv.new();
      obj.envs().map(function(e) {
        return self.eval(e);
      }).each(function(env) {
        return env.each_pair(function(k, v) {
          return env1._set(k, v);
        });
      });
      expr1 = self.eval(obj.expr());
      return Eval.eval(expr1, new EnsoHash ({ env: env1 }));
    };
  });

  var EvalStencilC = MakeClass("EvalStencilC", null, [EvalStencil],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Construct = {
    eval: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = EvalStencilC.new();
      return interp.dynamic_bind(function() {
        return interp.eval(obj);
      }, args);
    },

    EvalStencil: EvalStencil,
    EvalStencilC: EvalStencilC,

  };
  return Construct;
})
