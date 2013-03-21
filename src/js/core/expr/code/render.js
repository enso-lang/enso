define([
  "core/semantics/code/interpreter"
],
function(Interpreter) {
  var Render ;
  var RenderExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.render = function(obj) {
      var self = this; 
      return self.dispatch("render", obj);
    };

    this.render_EBinOp = function(op, e1, e2) {
      var self = this; 
      return S(self.render(e1), " ", op, " ", self.render(e2));
    };

    this.render_EUnOp = function(op, e) {
      var self = this; 
      return S(op, " ", self.render(e));
    };

    this.render_EField = function(e, fname) {
      var self = this; 
      return S(self.render(e), ".", fname);
    };

    this.render_EVar = function(name) {
      var self = this; 
      return name;
    };

    this.render_EConst = function(val) {
      var self = this; 
      return val;
    };

    this.render_ENil = function() {
      var self = this; 
      return "";
    };
  });

  var RenderExprC = MakeClass("RenderExprC", null, [RenderExpr],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Render = {
    RenderExpr: RenderExpr,
    RenderExprC: RenderExprC,

  };
  return Render;
})
