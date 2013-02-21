define([
  "core/expr/code/eval",
  "core/semantics/code/interpreter",
  "core/expr/code/env"
],
function(Eval, Interpreter, Env) {

  var Lvalue ;
  var Address = MakeClass("Address", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(array, index) {
        var self = this; 
        self.$.array = array;
        self.$.index = index;
        if (! self.$.array.has_key_P(self.$.index)) {
          return self.$.array._set(self.$.index, null);
        }
      };

      this.array = function() { return this.$.array };

      this.index = function() { return this.$.index };

      this.set_value = function(val) {
        var self = this; 
        var val;
        if (self.type()) {
          if (self.type().name() == "int") {
            val = val.to_i();
          } else if (self.type().name() == "str") {
            val = val.to_s();
          } else if (self.type().name() == "real") {
            val = val.to_f();
          }
        }
        try {
          return self.$.array._set(self.$.index, val);
        } catch ( DUMMY ) {
        }
      };

      this.value = function() {
        var self = this; 
        return self.$.array._get(self.$.index);
      };

      this.to_s = function() {
        var self = this; 
        return S(self.$.array, "[", self.$.index, "]");
      };

      this.type = function() {
        var self = this; 
        if (System.test_type(self.$.array, Env.ObjEnv)) {
          return self.$.array.type(self.$.index);
        } else {
          return null;
        }
      };

      this.object = function() {
        var self = this; 
        if (System.test_type(self.$.array, Env.ObjEnv)) {
          return self.$.array.obj();
        } else {
          return null;
        }
      };
    });

  var LValueExpr = MakeMixin([Eval.EvalExpr, Interpreter.Dispatcher], function() {
    this.lvalue = function(obj) {
      var self = this; 
      return self.dispatch("lvalue", obj);
    };

    this.lvalue_EField = function(e, fname) {
      var self = this; 
      return Address.new(Env.ObjEnv.new(self.eval(e)), fname);
    };

    this.lvalue_EVar = function(name) {
      var self = this; 
      return Address.new(self.$.D._get("env"), name);
    };

    this.lvalue__P = function(type, fields, args) {
      var self = this; 
      return null;
    };
  });

  var LValueExprC = MakeClass("LValueExprC", null, [LValueExpr],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Lvalue = {
    Address: Address,
    LValueExpr: LValueExpr,
    LValueExprC: LValueExprC,

  };
  return Lvalue;
})
