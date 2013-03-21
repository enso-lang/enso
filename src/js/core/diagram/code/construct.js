define([
  "core/expr/code/eval",
  "core/expr/code/render",
  "core/semantics/code/interpreter",
  "core/expr/code/impl",
  "core/expr/code/env",
  "core/schema/code/factory",
  "core/system/load/load",
  "core/system/library/schema",
  "core/schema/tools/union"
],
function(Eval, Render, Interpreter, Impl, Env, Factory, Load, Schema, Union) {
  var Construct ;

  var EvalStencil = MakeMixin([Interpreter.Dispatcher, Impl.EvalCommand], function() {
    this.eval_Stencil = function(title, root, body) {
      var self = this; 
      var factory, res, env;
      factory = Factory.SchemaFactory.new(Load.load("diagram.schema"));
      res = factory.Stencil(title, root);
      env = new EnsoHash ({ });
      env._set("data", self.$.D._get("data"));
      self.dynamic_bind(function() {
        return res.set_body(self.eval(body));
      }, new EnsoHash ({ env: env, factory: factory, props: new EnsoHash ({ }) }));
      return res;
    };

    this.handle_props = function(props) {
      var self = this; 
      var nprops, p1;
      nprops = self.$.D._get("props").clone();
      props.each(function(p) {
        p1 = self.eval(p);
        return nprops._set(Render.render(p1.var()), p1);
      });
      return nprops;
    };

    this.eval__P = function(type, obj, args) {
      var self = this; 
      var factory, res, nprops, ev;
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
                  return ev.flatten().each(function(e) {
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

    this.eval_Prop = function(var_V, val) {
      var self = this; 
      var factory, res;
      factory = self.$.D._get("factory");
      res = factory.Prop();
      res.set_var(factory.EStrConst(Render.RenderExprC.new().render(var_V)));
      res.set_val(Eval.make_const(factory, self.eval(val)));
      return res;
    };

    this.eval_EFor = function(var_V, list, body) {
      var self = this; 
      var nenv;
      nenv = Env.HashEnv.new(new EnsoHash ({ }), self.$.D._get("env"));
      return self.eval(list).map(function(val) {
        nenv._set(var_V, val);
        return self.dynamic_bind(function() {
          return self.eval(body);
        }, new EnsoHash ({ env: nenv }));
      });
    };

    this.eval_Pages = function(label, props, items, current) {
      var self = this; 
      var factory, res, nprops, ev, neval;
      factory = self.$.D._get("factory");
      res = factory.Pages();
      nprops = self.handle_props(props);
      nprops.values().each(function(p) {
        return res.props().push(p);
      });
      items.each(function(item) {
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
      if (current.Eval_P()) {
        neval = factory.Eval();
        res.set_current(neval);
      } else {
        res.set_current(Union.Copy(factory, current));
      }
      if (! (label == null)) {
        self.$.D._get("env")._set(label, res);
      }
      return res;
    };
  });

  var EvalExpr = MakeMixin([Interpreter.Dispatcher, Eval.EvalExpr], function() {
    this.eval_Color = function(r, g, b) {
      var self = this; 
      var factory, r1, g1, b1;
      factory = self.$.D._get("factory");
      r1 = Eval.make_const(factory, Math.round(self.eval(r)));
      g1 = Eval.make_const(factory, Math.round(self.eval(g)));
      b1 = Eval.make_const(factory, Math.round(self.eval(b)));
      return factory.Color(r1, g1, b1);
    };

    this.eval_InstanceOf = function(base, class_name) {
      var self = this; 
      var a;
      a = self.eval(base);
      return a && Schema.subclass_P(a.schema_class(), class_name);
    };

    this.eval_Eval = function(expr, envs) {
      var self = this; 
      var env1, expr1;
      env1 = Env.HashEnv.new();
      envs.map(function(e) {
        return self.eval(e);
      }).each(function(env) {
        return env.each_pair(function(k, v) {
          return env1._set(k, v);
        });
      });
      expr1 = self.eval(expr);
      return Eval.eval(expr1, new EnsoHash ({ env: env1 }));
    };

    this.eval_ETernOp = function(op1, op2, e1, e2, e3) {
      var self = this; 
      var dynamic, v, a, b;
      dynamic = self.$.D._get("dynamic");
      if (! dynamic) {
        return self.super();
      } else {
        v = self.eval(e1);
        if (! System.test_type(v, Variable)) {
          self.fail(S("NON_DYNAMIC ", v));
        }
        a = self.eval(e2);
        b = self.eval(e3);
        return v.test(a, b);
      }
    };

    this.eval_EBinOp = function(op, e1, e2) {
      var self = this; 
      var dynamic, r1, r2;
      dynamic = self.$.D._get("dynamic");
      if (! dynamic) {
        return super$.eval_EBinOp.call(self, op, e1, e2);
      } else {
        r1 = self.eval(e1);
        if (r1 && ! System.test_type(r1, Variable)) {
          r1 = Variable.new("gen", r1);
        }
        r2 = self.eval(e2);
        if (r2 && ! System.test_type(r2, Variable)) {
          r2 = Variable.new("gen", r2);
        }
        return r1.send(op.to_s(), r2);
      }
    };

    this.eval_EUnOp = function(op, e) {
      var self = this; 
      var dynamic, r1;
      dynamic = self.$.D._get("dynamic");
      if (! dynamic) {
        return super$.eval_EUnOp.call(self, op, e);
      } else {
        r1 = self.eval(self.e1());
        if (r1 && ! System.test_type(r1, Variable)) {
          r1 = Variable.new("gen", r1);
        }
        return r1.send(op.to_s());
      }
    };

    this.eval_EField = function(e, fname) {
      var self = this; 
      var in_fc, dynamic, r;
      in_fc = self.$.D._get("in_fc");
      dynamic = self.$.D._get("dynamic");
      if (in_fc || ! dynamic) {
        return super$.eval_EField.call(self, e, fname);
      } else {
        r = self.eval(e);
        if (System.test_type(r, Variable)) {
          r = r.value().dynamic_update();
        } else {
          r = r.dynamic_update();
        }
        return r.send(fname);
      }
    };
  });

  var EvalStencilC = MakeClass("EvalStencilC", null, [EvalExpr, EvalStencil],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Construct = {
    eval: function(obj, fields) {
      var self = this; 
      var interp;
      interp = EvalStencilC.new();
      return interp.dynamic_bind(function() {
        return interp.eval(obj);
      }, fields);
    },

    EvalStencil: EvalStencil,
    EvalExpr: EvalExpr,
    EvalStencilC: EvalStencilC,

  };
  return Construct;
})
