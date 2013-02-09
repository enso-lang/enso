require ( "enso" )
DynamicUpdateProxy = MakeClass( EnsoProxyObject, {
  initialize: function(obj) {
    var self = this; 
    var super$ = this.super$.initialize;
    self.$.obj = obj;
    return self.$.fields = new EnsoHash ( { } );
  },

  _get: function(name) {
    var self = this; 
    var var_V, field, val;
    var super$ = this.super$._get;
    var_V = self.$.fields._get(name);
    if (var_V) {
      return var_V;
    } else if (! name.is_a_P(Variable) && name.start_with_P("_")) {
      return self.$.obj.send(name.to_sym());
    } else {
      field = self.$.obj.schema_class().all_fields()._get(name);
      if (field.many()) {
        return self.$.obj._get(name);
      } else {
        val = self.$.obj._get(name);
        if (val.is_a_P(ManagedData.MObject())) {
          val = val.dynamic_update();
        }
        self.$.fields ._set( name , var_V = Variable.new(S(self.$.obj, ".", name), val) );
        self.$.obj.add_listener(function(val) {
          return var_V.value() = val;
        }, name);
        return var_V;
      }
    }
  },

  _set: function(name, val) {
    var self = this; 
    var super$ = this.super$._set;
    return self.$.obj ._set( name , self.args()._get(0) );
  },

  to_s: function() {
    var self = this; 
    var super$ = this.super$.to_s;
    return S("[", self.$.obj.to_s(), "]");
  },

  dynamic_update: function() {
    var self = this; 
    var super$ = this.super$.dynamic_update;
    return self;
  },

  schema_class: function() {
    var self = this; 
    var super$ = this.super$.schema_class;
    return self.$.obj.schema_class();
  }
});

exports = ManagedData = {
  DynamicUpdateProxy: DynamicUpdateProxy,

}
