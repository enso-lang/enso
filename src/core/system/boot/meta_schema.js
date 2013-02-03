require ( "enso" )
MObject = MakeClass( EnsoProxyObject, {
  _class_: {
    seq_no: 0
  },

  _id: function() { return this.$._id },

  initialize: function(data, root) {
    var self = this; 
    var super$ = this.super$.initialize;
    self.$._id = self._class_.seq_no = self._class_.seq_no + 1;
    self.$.data = data;
    return self.$.root = root || self;
  },

  schema_class: function() {
    var self = this; 
    var res;
    var super$ = this.super$.schema_class;
    res = self.$.root.types()._get(self.$.data._get("class"));
    self.define_singleton_method(function() {
      return res;
    }, "schema_class");
    return res;
  },

  _get: function(sym) {
    var self = this; 
    var res;
    var super$ = this.super$._get;
    res = sym._get(- 1) == "?"
      ? self.schema_class().name() == sym.slice(0, sym.length() - 1)
      : self.$.data.has_key_P(S(sym, "="))
        ? self.$.data._get(S(sym, "="))
        : self.$.data.has_key_P(S(sym, "#"))
          ? Boot.make_field(self.$.data._get(S(sym, "#")), self.$.root, true)
          : self.$.data.has_key_P(sym.to_s())
            ? Boot.make_field(self.$.data._get(sym.to_s()), self.$.root, false)
            : System.raise(S("Trying to deref nonexistent field ", sym, " in ", self.$.data.to_s().slice(0, 300)))
    ;
    self.define_singleton_method(function() {
      return res;
    }, sym);
    return res;
  },

  eql_P: function(other) {
    var self = this; 
    var super$ = this.super$.eql_P;
    return self._id() == other._id();
  },

  to_s: function() {
    var self = this; 
    var super$ = this.super$.to_s;
    return self.$.name || (self.$.name = ((function(){ {
      try {
        return S("<", self.$.data._get("class"), " ", self.name(), ">");
      } catch ( DUMMY ) {
        return S("<", self.$.data._get("class"), " ", self._id(), ">");
      }
    } })()));
  }
});

Schema = MakeClass( MObject, {
  classes: function() {
    var self = this; 
    var super$ = this.super$.classes;
    return BootManyField.new(self.types().select(function(t) {
      return t.Class_P();
    }), self.$.root, true);
  },

  primitives: function() {
    var self = this; 
    var super$ = this.super$.primitives;
    return BootManyField.new(self.types().select(function(t) {
      return t.Primitive_P();
    }), self.$.root, true);
  }
});

Class = MakeClass( MObject, {
  all_fields: function() {
    var self = this; 
    var super$ = this.super$.all_fields;
    return BootManyField.new(self.supers().flat_map(function(s) {
      return s.all_fields();
    }) + self.defined_fields(), self.$.root, true);
  },

  fields: function() {
    var self = this; 
    var super$ = this.super$.fields;
    return BootManyField.new(self.all_fields().select(function(f) {
      return ! f.computed();
    }), self.$.root, true);
  }
});

BootManyField = MakeClass( Array, {
  initialize: function(arr, root, keyed) {
    var self = this; 
    var super$ = this.super$.initialize;
    arr.each(function(obj) {
      return self.push(obj);
    });
    self.$.root = root;
    return self.$.keyed = keyed;
  },

  _get: function(key) {
    var self = this; 
    var super$ = this.super$._get;
    if (self.$.keyed) {
      return self.find(function(obj) {
        return obj.name() == key;
      });
    } else {
      return self.at(key);
    }
  },

  has_key_P: function(key) {
    var self = this; 
    var super$ = this.super$.has_key_P;
    return self._get(key);
  },

  each_with_match: function(block, other) {
    var self = this; 
    var other, ks, a, b;
    var super$ = this.super$.each_with_match;
    if (self.$.keyed) {
      other = other || new EnsoHash ( { } );
      ks = self.keys() || other.keys();
      return ks.each(function(k) {
        return block.call(self._get(k), other._get(k));
      });
    } else {
      a = Array(self);
      b = Array(other);
      return Range.new(0, [a.length(), b.length()].max() - 1).each(function(i) {
        return block.call(a._get(i), b._get(i));
      });
    }
  },

  keys: function() {
    var self = this; 
    var super$ = this.super$.keys;
    if (self.$.keyed) {
      return self.map(function(o) {
        return o.name();
      });
    } else {
      return null;
    }
  }
});

exports = Boot = {
  MObject: MObject,
  Schema: Schema,
  Class: Class,
  BootManyField: BootManyField,

  load_path: function(path) {
    return Boot.load(System.readJSON(path));
  },

  load: function(doc) {
    ss0 = Boot.make_object(doc, null);
    return ss0; return Copy(ManagedData.new(ss0), ss0);
  },

  make_object: function(data, root) {
    if (data._get("class") == "Schema") {
      return Schema.new(data, root);
    } else if (data._get("class") == "Class") {
      return Class.new(data, root);
    } else {
      return MObject.new(data, root);
    }
  },

  make_field: function(data, root, keyed) {
    if (data.is_a_P(Array)) {
      return Boot.make_many(data, root, keyed);
    } else {
      return Boot.get_object(data, root);
    }
  },

  get_object: function(data, root) {
    if (! data) {
      return null;
    } else if (data.is_a_P(String)) {
      return Paths.parse(data).deref(root);
    } else {
      return Boot.make_object(data, root);
    }
  },

  make_many: function(data, root, keyed) {
    arr = data.map(function(a) {
      return Boot.get_object(a, root);
    });
    return BootManyField.new(arr, root, keyed);
  }
}
 x = Boot.load_path("/Users/wcook/enso/src/core/system/boot/schema_schema.json");
console.log("x._id = " + x._id()) ;
console.log("Test = " + x.types().to_s());
console.log("Test = " + x.types()._get("Primitive").name()) ;
console.log("Test = " + x.types()._get("Primitive").to_s()) ;
 