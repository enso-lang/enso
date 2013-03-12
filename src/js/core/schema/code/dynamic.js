define([
  "enso"
],
function(Enso) {
  var Dynamic ;
  var DynamicUpdateProxy = MakeClass("DynamicUpdateProxy", EnsoProxyObject, [],
    function() {
    },
    function(super$) {
      this.initialize = function(obj) {
        var self = this; 
        self.$.obj = obj;
        self.$.fields = new EnsoHash ({ });
        return self.$.obj.schema_class().fields().each(function(fld) {
          self.define_getter(fld.name(), self.$.obj.props()._get(fld.name()));
          return self.define_setter(fld.name(), self.$.obj.props()._get(fld.name()));
        });
      };

      this._get = function(name) {
        var self = this; 
        var var_V, field, val;
        var_V = self.$.fields._get(name);
        if (var_V) {
          return var_V;
        } else if (! System.test_type(name, Variable) && name.start_with_P("_")) {
          return self.$.obj.send(name.to_sym());
        } else {
          field = self.$.obj.schema_class().all_fields()._get(name);
          if (field.many()) {
            return self.$.obj._get(name);
          } else {
            val = self.$.obj._get(name);
            if (System.test_type(val, Factory.MObject)) {
              val = val.dynamic_update();
            }
            self.$.fields._set(name, var_V = Variable.new(S(self.$.obj, ".", name), val));
            self.$.obj.add_listener(function(val) {
              return var_V.set_value(val);
            }, name);
            return var_V;
          }
        }
      };

      this._set = function(name, val) {
        var self = this; 
        return self.$.obj._set(name, self.args()._get(0));
      };

      this.to_s = function() {
        var self = this; 
        return S("[", self.$.obj.to_s(), "]");
      };

      this.dynamic_update = function() {
        var self = this; 
        return self;
      };

      this.schema_class = function() {
        var self = this; 
        return self.$.obj.schema_class();
      };
    });

  Dynamic = {
    DynamicUpdateProxy: DynamicUpdateProxy,

  };
  return Dynamic;
})
