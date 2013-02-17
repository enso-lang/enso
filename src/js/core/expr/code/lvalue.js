define([
  "core/expr/code/eval",
  "core/semantics/code/interpreter"
],
function(Eval, Interpreter) {

  var Lvalue ;
  var Address = MakeClass( {
    initialize: function(array, index) {
      var self = this; 
      var super$ = this.super$.initialize;
      self.$.array = array;
      self.$.index = index;
      if (! self.$.array.has_key_P(self.$.index)) {
        return self.$.array ._set( self.$.index , null );
      }
    },

    array: function() { return this.$.array },

    index: function() { return this.$.index },

    set_value: function(val) {
      var self = this; 
      var val;
      var super$ = this.super$.set_value;
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
        return self.$.array ._set( self.$.index , val );
      } catch ( DUMMY ) {
      }
    },

    value: function() {
      var self = this; 
      var super$ = this.super$.value;
      return self.$.array._get(self.$.index);
    },

    to_str: function() {
      var self = this; 
      var super$ = this.super$.to_str;
      return S(self.$.array, "[", self.$.index, "]");
    },

    type: function() {
      var self = this; 
      var super$ = this.super$.type;
      if (System.test_type(self.$.array, Env.ObjEnv())) {
        return self.$.array.type(self.$.index);
      } else {
        return null;
      }
    },

    object: function() {
      var self = this; 
      var super$ = this.super$.object;
      if (System.test_type(self.$.array, Env.ObjEnv())) {
        return self.$.array.obj();
      } else {
        return null;
      }
    }
  });

  var LValueExpr = MakeMixin({
    include: [ Eval. EvalExpr , Interpreter. Dispatcher ],

    lvalue: function(obj) {
      var self = this; 
      var super$ = this.super$.lvalue;
      return self.dispatch("lvalue", obj);
    },

    lvalue_EField: function(e, fname) {
      var self = this; 
      var super$ = this.super$.lvalue_EField;
      return Address.new(Env.ObjEnv().new(self.eval(e)), fname);
    },

    lvalue_EVar: function(name) {
      var self = this; 
      var super$ = this.super$.lvalue_EVar;
      return Address.new(self.$.D._get("env"), name);
    },

    lvalue__P: function(type, fields, args) {
      var self = this; 
      var super$ = this.super$.lvalue__P;
      return null;
    }
  });

  var LValueExprC = MakeClass( {
    include: [ LValueExpr ],

    initialize: function() {
      var self = this; 
      var super$ = this.super$.initialize;
    }
  });

  Lvalue = {
    Address: Address,
    LValueExpr: LValueExpr,
    LValueExprC: LValueExprC,

  };
  return Lvalue;
})
