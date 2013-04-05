define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/expr/code/renderexp",
  "core/semantics/code/interpreter",
  "core/expr/code/impl",
  "core/expr/code/env",
  "core/schema/code/factory",
  "core/system/load/load",
  "core/system/library/schema",
  "core/schema/tools/union",
  "core/diagram/code/traceval",
  "core/diagram/code/evalexprstencil"
],
function(Eval, Lvalue, Renderexp, Interpreter, Impl, Env, Factory, Load, Schema, Union, Traceval, Evalexprstencil) {
  var Construct ;

  var EvalStencil = MakeMixin([Interpreter.Dispatcher, Evalexprstencil.EvalExprStencil], function() {
    this.eval_Stencil = function(obj) {
      var self = this; 
      var factory, res, env, src;
      factory = Factory.SchemaFactory.new(Load.load("diagram.schema"));
      res = factory.Stencil(obj.title(), obj.root());
      env = new EnsoHash ({ });
      env._set("data", self.$.D._get("data"));
      src = new EnsoHash ({ });
      self.dynamic_bind(function() {
        return res.set_body(self.eval(obj.body()));
      }, new EnsoHash ({ env: env, factory: factory, src: src, srctemp: new EnsoHash ({ }), props: new EnsoHash ({ }) }));
      return res;
    };

    this.flatten = function(arr) {
      var self = this; 
      var res;
      if (System.test_type(arr, Array)) {
        res = [];
        arr.each(function(a) {
          return res = res.concat(self.flatten(a));
        });
        return res;
      } else if (arr == null) {
        return [];
      } else {
        return [arr];
      }
    };

    this.eval__P = function(obj) {
      var self = this; 
      var type, factory, res, addr, ev;
      type = obj.schema_class();
      factory = self.$.D._get("factory");
      res = factory._get(type.name());
      type.fields().each(function(f) {
        if (f.type().name() == "Expr") {
          if (obj._get(f.name()) == null) {
            return res._set(f.name(), null);
          } else if (! f.many()) {
            res._set(f.name(), Eval.make_const(factory, self.eval(obj._get(f.name()))));
            addr = self.$.D._get("src")._get(obj._get(f.name()));
            if (! (addr == null)) {
              return self.$.D._get("modelmap")._set(res._get(f.name()).to_s(), addr);
            }
          } else {
            return obj._get(f.name()).each(function(item) {
              ev = self.eval(item);
              if (System.test_type(ev, Array)) {
                return ev.each(function(e) {
                  if (! (e == null)) {
                    return res._get(f.name()).push(factory.Label(Eval.make_const(factory, e)));
                  }
                });
              } else if (! (ev == null)) {
                return res._get(f.name()).push(factory.Label(Eval.make_const(factory, ev)));
              }
            });
          }
        } else if (f.type().Primitive_P()) {
          return res._set(f.name(), obj._get(f.name()));
        } else if (! f.many()) {
          return res._set(f.name(), self.eval(obj._get(f.name())));
        } else {
          return obj._get(f.name()).each(function(item) {
            ev = self.eval(item);
            return self.flatten(ev).each(function(e) {
              return res._get(f.name()).push(e);
            });
          });
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
      res.set_var(obj.var());
      res.set_val(Eval.make_const(factory, self.eval(obj.val())));
      return res;
    };

    this.eval_SelectMulti = function(obj) {
      var self = this; 
      var type, factory, res, cs;
      type = obj.schema_class();
      factory = self.$.D._get("factory");
      res = factory._get(type.name());
      res.set_label(obj.label());
      obj.props().each(function(prop) {
        return res.props().push(factory.Prop(prop.var(), Eval.make_const(factory, self.eval(prop.val()))));
      });
      res.set_value(Eval.make_const(factory, self.eval(obj.value())));
      obj.choices().each(function(choice) {
        cs = self.eval(choice);
        return cs.each(function(c) {
          return res.choices().push(Eval.make_const(factory, c));
        });
      });
      return res;
    };

    this.eval_SelectSingle = function(obj) {
      var self = this; 
      var type, factory, res, cs;
      type = obj.schema_class();
      factory = self.$.D._get("factory");
      res = factory._get(type.name());
      res.set_label(obj.label());
      obj.props().each(function(prop) {
        return res.props().push(factory.Prop(prop.var(), Eval.make_const(factory, self.eval(prop.val()))));
      });
      res.set_value(Eval.make_const(factory, self.eval(obj.value())));
      obj.choices().each(function(choice) {
        cs = self.eval(choice);
        return cs.each(function(c) {
          return res.choices().push(Eval.make_const(factory, c));
        });
      });
      return res;
    };

    this.eval_Pages = function(obj) {
      var self = this; 
      var factory, res, ev, neval;
      factory = self.$.D._get("factory");
      res = factory.Pages();
      res.set_label(obj.label());
      obj.props().each(function(prop) {
        return res.props().push(factory.Prop(prop.var(), Eval.make_const(factory, self.eval(prop.val()))));
      });
      obj.items().each(function(item) {
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
