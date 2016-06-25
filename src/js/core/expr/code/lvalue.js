define(["core/expr/code/eval", "core/semantics/code/interpreter", "core/expr/code/env"], (function (Eval, Interpreter, Env) {
  var Lvalue;
  var Address = MakeClass("Address", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (array, index) {
      var self = this;
      (self.$.array = array);
      (self.$.index = index);
      if ((!self.$.array.has_key_P(self.$.index))) {
        return self.$.array._set(self.$.index, null);
      }
    }));
    (this.array = (function () {
      return this.$.array;
    }));
    (this.index = (function () {
      return this.$.index;
    }));
    (this.set_value = (function (val) {
      var self = this;
      if (self.type()) {
        switch ((function () {
          return self.type().name();
        })()) {
          case "real":
           (val = val.to_f());
           break;
          case "str":
           (val = val.to_s());
           break;
          case "int":
           (val = val.to_i());
           break;
        }
            
      }
      try {return self.$.array._set(self.$.index, val);
           
      }
      catch (caught$848) {
        
      }
    }));
    (this.set = (function (val) {
      var self = this;
      if (self.type()) {
        switch ((function () {
          return self.type().name();
        })()) {
          case "real":
           (val = val.to_f());
           break;
          case "str":
           (val = val.to_s());
           break;
          case "int":
           (val = val.to_i());
           break;
        }
            
      }
      try {return self.$.array._set(self.$.index, val);
           
      }
      catch (caught$1146) {
        
      }
    }));
    (this.value = (function () {
      var self = this;
      return self.$.array._get(self.$.index);
    }));
    (this.get = (function () {
      var self = this;
      return self.$.array._get(self.$.index);
    }));
    (this.to_s = (function () {
      var self = this;
      return S("", self.$.array, "[", self.$.index, "]");
    }));
    (this.type = (function () {
      var self = this;
      return (System.test_type(self.$.array, Env.ObjEnv) ? self.$.array.type(self.$.index) : null);
    }));
    (this.object = (function () {
      var self = this;
      return (System.test_type(self.$.array, Env.ObjEnv) ? self.$.array.obj() : null);
    }));
  }));
  var LValueExpr = MakeMixin([Eval.EvalExpr, Interpreter.Dispatcher], (function () {
    (this.lvalue = (function (obj) {
      var self = this;
      return self.dispatch_obj("lvalue", obj);
    }));
    (this.lvalue_EField = (function (obj) {
      var self = this;
      return Address.new(Env.ObjEnv.new(self.eval(obj.e())), obj.fname());
    }));
    (this.lvalue_EVar = (function (obj) {
      var self = this;
      return Address.new(self.$.D._get("env"), obj.name());
    }));
    (this.lvalue__P = (function (obj) {
      var self = this;
      return null;
    }));
  }));
  var LValueExprC = MakeClass("LValueExprC", null, [LValueExpr], (function () {
  }), (function (super$) {
  }));
  (Lvalue = {
    lvalue: (function (obj, args) {
      var self = this;
      (args = (((typeof args) !== "undefined") ? args : (new EnsoHash({
        
      }))));
      var interp;
      (interp = LValueExprC.new());
      return interp.dynamic_bind((function () {
        return interp.lvalue(obj);
      }), args);
    }),
    LValueExprC: LValueExprC,
    Address: Address,
    LValueExpr: LValueExpr
  });
  return Lvalue;
}));