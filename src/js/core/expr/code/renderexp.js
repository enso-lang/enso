define([
  "core/semantics/code/interpreter"
],
function(Interpreter) {
  var Renderexp ;

  var RenderExpr = MakeMixin([Interpreter.Dispatcher], function() {
    this.render = function(obj) {
      var self = this; 
      return self.dispatch_obj("render", obj);
    };

    this.render_EBinOp = function(obj) {
      var self = this; 
      return S(self.render(obj.e1()), " ", obj.op(), " ", self.render(obj.e2()));
    };

    this.render_EUnOp = function(obj) {
      var self = this; 
      return S(obj.op(), " ", self.render(obj.e()));
    };

    this.render_EField = function(obj) {
      var self = this; 
      return S(self.render(obj.e()), ".", obj.fname());
    };

    this.render_EVar = function(obj) {
      var self = this; 
      return obj.name();
    };

    this.render_EConst = function(obj) {
      var self = this; 
      return obj.val();
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
    });

  Renderexp = {
    render: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = RenderExprC.new();
      return interp.dynamic_bind(function() {
        return interp.render(obj);
      }, args);
    },

    RenderExpr: RenderExpr,
    RenderExprC: RenderExprC,

  };
  return Renderexp;
})
