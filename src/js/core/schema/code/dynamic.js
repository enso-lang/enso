'use strict'

//// Dynamic ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Dynamic;

class DynamicUpdateProxy extends Enso.EnsoProxyObject {
  static new(...args) { return new DynamicUpdateProxy(...args) };

  constructor(obj) {
    super();
    var self = this;
    self.obj$ = obj;
    self.fields$ = Enso.EMap.new();
    self.obj$.schema_class().fields().each(function(fld) {
      self.define_getter(fld.name(), self.obj$.props().get$(fld.name()));
      return self.define_setter(fld.name(), self.obj$.props().get$(fld.name()));
    });
  };

  get(name) {
    var self = this, variable, field, val;
    variable = self.fields$.get$(name);
    if (variable) {
      return variable;
    } else if (! Enso.System.test_type(name, Variable) && name.start_with_P("_")) {
      return self.obj$.send(name.to_sym());
    } else {
      field = self.obj$.schema_class().all_fields().get$(name);
      if (field.many()) {
        return self.obj$.get$(name);
      } else {
        val = self.obj$.get$(name);
        if (Enso.System.test_type(val, Factory.MObject)) {
          val = val.dynamic_update();
        }
        self.fields$ .set$(name, variable = Variable.new(Enso.S(self.obj$, ".", name), val));
        self.obj$.add_listener(function(val) {
          return variable.set_value(val);
        }, name);
        return variable;
      }
    }
  };

  _set(name, val) {
    var self = this;
    return self.obj$ .set$(name, self.args().get$(0));
  };

  to_s() {
    var self = this;
    return Enso.S("[", self.obj$.to_s(), "]");
  };

  dynamic_update() {
    var self = this;
    return self;
  };

  schema_class() {
    var self = this;
    return self.obj$.schema_class();
  };
};

Dynamic = {
  DynamicUpdateProxy: DynamicUpdateProxy,
};
module.exports = Dynamic ;
