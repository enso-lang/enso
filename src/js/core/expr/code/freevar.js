define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter"
],
function(Eval, Lvalue, Interpreter) {
  var Freevar ;

  var FreeVarExpr = MakeMixin([Eval.EvalExpr, Lvalue.LValueExpr, Interpreter.Dispatcher], function() {
    this.depends = function(obj) {
      var self = this; 
      return self.dispatch_obj("depends", obj);
    };

    this.depends_EField = function(obj) {
      var self = this; 
      return [];
    };

    this.depends_EVar = function(obj) {
      var self = this; 
      if (self.$.D._get("bound").include_P(obj.name()) || obj.name() == "self") {
        return [];
      } else {
        return [Lvalue.Address.new(self.$.D._get("env"), obj.name())];
      }
    };

    this.depends_ELambda = function(obj) {
      var self = this; 
      var bound2;
      bound2 = self.$.D._get("bound").clone();
      obj.formals().each(function(f) {
        return bound2.push(self.depends(f));
      });
      return self.dynamic_bind(function() {
        return self.depends(obj.body());
      }, new EnsoHash ({ bound: bound2 }));
    };

    this.depends_Formal = function(obj) {
      var self = this; 
      return obj.name();
    };

    this.depends__P = function(obj) {
      var self = this; 
      var res, type;
      res = [];
      type = obj.schema_class();
      type.fields().each(function(f) {
        if ((f.traversal() && ! f.type().Primitive_P()) && obj._get(f.name())) {
          if (! f.many()) {
            return res = res.concat(self.depends(obj._get(f.name())));
          } else {
            return obj._get(f.name()).each(function(o) {
              return res = res.concat(self.depends(o));
            });
          }
        }
      });
      return res;
    };
  });

  var FreeVarExprC = MakeClass("FreeVarExprC", null, [FreeVarExpr],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Freevar = {
    depends: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = FreeVarExprC.new();
      return interp.dynamic_bind(function() {
        return interp.depends(obj);
      }, args);
    },

    FreeVarExpr: FreeVarExpr,
    FreeVarExprC: FreeVarExprC,

  };
  return Freevar;
})
