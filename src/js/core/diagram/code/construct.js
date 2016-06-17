define([
],
function() {
  var EvalStencil ;

  EvalStencil = {
    eval_Color: function(r, g, b, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      return args._get("factory").Color(self.eval(r, args).round(), self.eval(g, args).round(), self.eval(b, args).round());
    },

    eval_InstanceOf: function(base, class_name, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var a;
      a = self.eval(base, args);
      return a && Subclass_P(a.schema_class(), class_name);
    },

    eval_ETernOp: function(op1, op2, e1, e2, e3, args) {
      var self = this; 
      if (args === undefined) args = null;
      var v, a, b;
      if (! args._get("dynamic")) {
        return EvalStencil.super();
      } else {
        v = self.eval(e1, args);
        if (! System.test_type(v, Variable)) {
          EvalStencil.fail(S("NON_DYNAMIC ", v));
        }
        a = self.eval(e2, args);
        b = self.eval(e3, args);
        return v.test(a, b);
      }
    },

    eval_EBinOp: function(op, e1, e2, args) {
      var self = this; 
      if (args === undefined) args = null;
      var r1, r2;
      if (! args._get("dynamic")) {
        return EvalStencil.super();
      } else {
        r1 = self.eval(e1, args);
        if (r1 && ! System.test_type(r1, Variable)) {
          r1 = Variable.new("gen", r1);
        }
        r2 = self.eval(e2, args);
        if (r2 && ! System.test_type(r2, Variable)) {
          r2 = Variable.new("gen", r2);
        }
        return r1.send(op.to_s(), r2);
      }
    },

    eval_EUnOp: function(op, e, args) {
      var self = this; 
      if (args === undefined) args = null;
      var r1;
      if (! args._get("dynamic")) {
        return EvalStencil.super();
      } else {
        r1 = self.eval(EvalStencil.e1(), args);
        if (r1 && ! System.test_type(r1, Variable)) {
          r1 = Variable.new("gen", r1);
        }
        return r1.send(op.to_s());
      }
    },

    eval_EFunCall: function(fun, params, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var nargs;
      nargs = args.clone();
      nargs._set("in_fc", true);
      return self.eval(fun, nargs).apply(self.eval(fun, nargs), [].concat(params.map(function(p) {
        return self.eval(p, args);
      })));
    },

    eval_EField: function(e, fname, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var r;
      if (args._get("in_fc")) {
        args._set("in_fc", false);
        return self.eval(e, args).method(fname.to_sym());
      } else {
        r = self.eval(e, args);
        if (args._get("dynamic")) {
          if (System.test_type(r, Variable)) {
            r = r.value().dynamic_update();
          } else {
            r = r.dynamic_update();
          }
        }
        if (fname == "_id") {
          return r._id();
        } else {
          return r._get(fname);
        }
      }
    },

  };
  return EvalStencil;
})
