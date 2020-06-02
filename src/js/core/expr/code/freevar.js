'use strict'

//// Freevar ////

var cwd = process.cwd() + '/';
var Eval = require(cwd + "core/expr/code/eval.js");
var Lvalue = require(cwd + "core/expr/code/lvalue.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Enso = require(cwd + "enso.js");

var Freevar;

var depends = function(obj, args = Enso.EMap.new()) {
  var self = this, interp;
  interp = FreeVarExprC.new();
  return interp.dynamic_bind(function() {
    return interp.depends(obj);
  }, args);
};

function FreeVarExpr(parent) {
  return class extends Enso.mix(parent, Eval.EvalExpr, Lvalue.LValueExpr, Interpreter.Dispatcher) {
    depends(obj) {
      var self = this;
      return self.dispatch_obj("depends", obj);
    };

    depends_EField(obj) {
      var self = this;
      return self.depends(obj.e());
    };

    depends_EVar(obj) {
      var self = this;
      if (self.D$.get$("bound").include_P(obj.name()) || obj.name() == "self") {
        return [];
      } else {
        return [Lvalue.Address.new(self.D$.get$("env"), obj.name())];
      }
    };

    depends_ELambda(obj) {
      var self = this, bound2;
      bound2 = self.D$.get$("bound").clone();
      obj.formals().each(function(f) {
        return bound2.push(self.depends(f));
      });
      return self.dynamic_bind(function() {
        return self.depends(obj.body());
      }, Enso.EMap.new({bound: bound2}));
    };

    depends_Formal(obj) {
      var self = this;
      return obj.name();
    };

    depends__P(obj) {
      var self = this, res, type;
      res = [];
      type = obj.schema_class();
      type.fields().each(function(f) {
        if ((f.traversal() && ! Enso.System.test_type(f.type(), "Primitive")) && obj.get$(f.name())) {
          if (! f.many()) {
            return res = res.concat(self.depends(obj.get$(f.name())));
          } else {
            return obj.get$(f.name()).each(function(o) {
              return res = res.concat(self.depends(o));
            });
          }
        }
      });
      return res;
    }; }};

class FreeVarExprC extends Enso.mix(Enso.EnsoBaseClass, FreeVarExpr) {
  static new(...args) { return new FreeVarExprC(...args) };

  constructor() {
    super();
  };
};

Freevar = {
  depends: depends,
  FreeVarExpr: FreeVarExpr,
  FreeVarExprC: FreeVarExprC,
};
module.exports = Freevar ;
