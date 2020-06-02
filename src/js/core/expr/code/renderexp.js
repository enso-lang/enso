'use strict'

//// Renderexp ////

var cwd = process.cwd() + '/';
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Enso = require(cwd + "enso.js");

var Renderexp;

var render = function(obj, args = Enso.EMap.new()) {
  var self = this, interp;
  interp = RenderExprC.new();
  return interp.dynamic_bind(function() {
    return interp.render(obj);
  }, args);
};

function RenderExpr(parent) {
  return class extends Enso.mix(parent, Interpreter.Dispatcher) {
    render(obj) {
      var self = this;
      return self.dispatch_obj("render", obj);
    };

    render_EBinOp(obj) {
      var self = this;
      return Enso.S(self.render(obj.e1()), " ", obj.op(), " ", self.render(obj.e2()));
    };

    render_EUnOp(obj) {
      var self = this;
      return Enso.S(obj.op(), " ", self.render(obj.e()));
    };

    render_EField(obj) {
      var self = this;
      return Enso.S(self.render(obj.e()), ".", obj.fname());
    };

    render_ESubscript(obj) {
      var self = this;
      return Enso.S(self.render(obj.e()), "[", self.render(obj.sub()), "]");
    };

    render_EVar(obj) {
      var self = this;
      return obj.name();
    };

    render_EConst(obj) {
      var self = this;
      return obj.val();
    };

    render_ENil() {
      var self = this;
      return "";
    }; }};

class RenderExprC extends Enso.mix(Enso.EnsoBaseClass, RenderExpr) {
  static new(...args) { return new RenderExprC(...args) };

};

Renderexp = {
  render: render,
  RenderExpr: RenderExpr,
  RenderExprC: RenderExprC,
};
module.exports = Renderexp ;
