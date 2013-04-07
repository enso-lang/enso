define([
  "core/semantics/code/interpreter",
  "core/expr/code/lvalue"
],
function(Interpreter, Lvalue) {
  var Invert ;

  var GetSourcesExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.getSources = function(obj) {
      var self = this; 
      return self.dispatch_obj("getSources", obj);
    };

    this.getSources_EBinOp = function(obj) {
      var self = this; 
      return self.getSources(obj.e1()).concat(self.getSources(obj.e2()));
    };

    this.getSources_EUnOp = function(obj) {
      var self = this; 
      return self.getSources(obj.e());
    };

    this.getSources_EVar = function(obj) {
      var self = this; 
      return [obj];
    };

    this.getSources_EConst = function(obj) {
      var self = this; 
      return [];
    };

    this.getSources_EField = function(obj) {
      var self = this; 
      return [obj];
    };
  });

  var InvertExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.invert = function(obj) {
      var self = this; 
      return self.dispatch_obj("invert", obj);
    };

    this.invert_EBinOp = function(obj) {
      var self = this; 
      var val;
      val = self.$.D._get("val");
      switch (obj.op()) {
        case "+":
          if (obj.e1().EConst_P()) {
            return self.dynamic_bind(function() {
              return self.invert(obj.e2());
            }, new EnsoHash ({ val: val - obj.e1().val() }));
          } else if (obj.e2().EConst_P()) {
            return self.dynamic_bind(function() {
              return self.invert(obj.e1());
            }, new EnsoHash ({ val: val - obj.e2().val() }));
          }
        default:
          return self.raise(S("Unknown operator (", obj.op(), ")"));
      }
    };

    this.invert_EVar = function(obj) {
      var self = this; 
      var val, addr;
      val = self.$.D._get("val");
      addr = Lvalue.lvalue(obj, new EnsoHash ({ env: self.$.D._get("env") }));
      return addr.set(val);
    };

    this.invert_EConst = function(obj) {
      var self = this; 
      if (self.$.D._get("val") != obj.val()) {
        return self.raise("Invert fail at constant");
      }
    };

    this.invert_EField = function(obj) {
      var self = this; 
      var val, addr;
      val = self.$.D._get("val");
      addr = Lvalue.lvalue(obj, new EnsoHash ({ env: self.$.D._get("env") }));
      return addr.set(val);
    };
  });

  var InvertExprC = MakeClass("InvertExprC", null, [InvertExpr, GetSourcesExpr],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Invert = {
    invert: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = InvertExprC.new();
      return interp.dynamic_bind(function() {
        return interp.invert(obj);
      }, args);
    },

    getSources: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = InvertExprC.new();
      return interp.dynamic_bind(function() {
        return interp.getSources(obj);
      }, args);
    },

    GetSourcesExpr: GetSourcesExpr,
    InvertExpr: InvertExpr,
    InvertExprC: InvertExprC,

  };
  return Invert;
})
