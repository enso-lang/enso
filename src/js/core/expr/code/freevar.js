define([
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter"
],
function(Eval, Lvalue, Interpreter) {

  var FreeVar ;
  var FreeVarExpr = MakeMixin({
    include: [ Eval. EvalExpr , Lvalue. LValueExpr , Interpreter. Dispatcher ],

    depends: function(obj) {
      var self = this; 
      var super$ = this.super$.depends;
      return self.dispatch("depends", obj);
    },

    depends_EField: function(e, fname) {
      var self = this; 
      var super$ = this.super$.depends_EField;
      return [];
    },

    depends_EVar: function(name) {
      var self = this; 
      var super$ = this.super$.depends_EVar;
      if (self.$.D._get("bound").include_P(name) || name == "self") {
        return [];
      } else {
        return [Lvalue.Address().new(self.$.D._get("env"), name)];
      }
    },

    depends_ELambda: function(body, formals) {
      var self = this; 
      var bound2;
      var super$ = this.super$.depends_ELambda;
      bound2 = self.$.D._get("bound").clone();
      formals.each(function(f) {
        return bound2.push(self.depends(f));
      });
      return self.dynamic_bind(function() {
        return self.depends(body);
      }, new EnsoHash ( { } ));
    },

    depends_Formal: function(name) {
      var self = this; 
      var super$ = this.super$.depends_Formal;
      return name;
    },

    depends__P: function(type, fields, args) {
      var self = this; 
      var res;
      var super$ = this.super$.depends__P;
      res = [];
      type.fields().each(function(f) {
        if ((f.traversal() && ! f.type().Primitive_P()) && fields._get(f.name())) {
          if (! f.many()) {
            return res = res + self.depends(fields._get(f.name()));
          } else {
            return fields._get(f.name()).each(function(o) {
              return res = res + self.depends(o);
            });
          }
        }
      });
      return res;
    }
  });

  var FreeVarExprC = MakeClass( {
    include: [ FreeVarExpr ],

    initialize: function() {
      var self = this; 
      var super$ = this.super$.initialize;
    }
  });

  FreeVar = {
    FreeVarExpr: FreeVarExpr,
    FreeVarExprC: FreeVarExprC,

  };
  return FreeVar;
})
