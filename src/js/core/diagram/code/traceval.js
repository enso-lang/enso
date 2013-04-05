define([
  "core/semantics/code/interpreter",
  "core/expr/code/impl"
],
function(Interpreter, Impl) {
  var Traceval ;

  var TracevalCommand = MakeMixin([Interpreter.Dispatcher, Impl.EvalCommand], function() {
    this.eval_EBinOp = function(obj) {
      var self = this; 
      var res, src;
      res = super$.eval_EBinOp.call(self, obj);
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
      res = super$.eval_EUnOp.call(self, obj);
      src = self.$.D._get("factory")._get(obj.schema_class().name());
      src.set_op(obj.op());
      src.set_e(self.$.D._get("src")._get(obj.e()));
      self.$.D._get("src")._set(obj, src);
      return res;
    };

    this.eval_EVar = function(obj) {
      var self = this; 
      var res, path;
      res = super$.eval_EVar.call(self, obj);
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
      res = super$.eval_EConst.call(self, obj);
      self.$.D._get("src")._set(obj, Eval.make_const(self.$.D._get("factory"), res));
      return res;
    };

    this.eval_EField = function(obj) {
      var self = this; 
      var res, src;
      res = super$.eval_EField.call(self, obj);
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
      var res, last;
      res = super$.eval_EBlock.call(self, obj);
      last = obj.body()._get(obj.body().size() - 1);
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(last));
      return res;
    };

    this.eval_EWhile = function(obj) {
      var self = this; 
      var res;
      res = super$.eval_EWhile.call(self, obj);
      self.$.D._get("src")._set(obj, self.$.D._get("src")._get(obj.body()));
      return res;
    };

    this.eval_EFor = function(obj) {
      var self = this; 
      var res;
      res = super$.eval_EFor.call(self, obj);
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
      super$.eval_EFunDef.call(self, obj);
      forms = [];
      obj.formals().each(function(f) {
        return forms.push(f.name());
      });
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
