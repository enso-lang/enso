require ( "enso" )

MObject = MakeClass( EnsoBaseObject, {
  _class_: {
    seq_no: 0
  },

  _id: function ( ) { return this.$._id },

  initialize: function( data, root ) {
    var self=this;
    self.$._id = self._class_.seq_no = self._class_.seq_no + 1;
    self.$.data = data;
    self.$.root = root || self;
  },

  schema_class: function( ) {
    var self=this;
    res = self.$.root.types()._get(self.$.data._get("class"));
    self.define_singleton_method(function() {
      return res;
    }, "schema_class");
    return res;
  },

  _get: function( sym ) {
    var self=this;
    res = sym._get(- 1) == "?"
      ? self.schema_class().name() == sym.slice(0, sym.length() - 1)
      : self.$.data.has_key_p(str(sym, "="))
        ? self.$.data._get(str(sym, "="))
        : self.$.data.has_key_p(str(sym, "#"))
          ? Boot.make_field(self.$.data._get(str(sym, "#")), self.$.root, true)
          : self.$.data.has_key_p(sym.to_s())
            ? Boot.make_field(self.$.data._get(sym.to_s()), self.$.root, false)
            : raise(str("Trying to deref nonexistent field ", sym, " in ", self.$.data.to_s().slice(0, 300)))
    ;
    self.define_singleton_method(function() {
      return res;
    }, sym);
    return res;
  },

  eql_p: function( other ) {
    var self=this;
    return self._id() == other._id();
  },

  to_s: function( ) {
    var self=this;
    return self.$.name || (self.$.name = ((function(){ {
      try {
        return str("<", self.$.data._get("class"), " ", self.name(), ">");
      } catch ( DUMMY ) {
        return str("<", self.$.data._get("class"), " ", self._id(), ">");
      }
    } })()));
  }
});

Schema = MakeClass( MObject, {
  classes: function( ) {
    var self=this;
    return BootManyField.new(self.types().select(), self.$.root, true);
  },

  primitives: function( ) {
    var self=this;
    return BootManyField.new(self.types().select(), self.$.root, true);
  }
});

Class = MakeClass( MObject, {
  all_fields: function( ) {
    var self=this;
    return BootManyField.new(self.supers().flat_map() + defined_fields, self.$.root, true);
  },

  fields: function( ) {
    var self=this;
    return BootManyField.new(self.all_fields().select(), self.$.root, true);
  }
});

BootManyField = MakeClass( Array, {
  initialize: function( arr, root, keyed ) {
    var self=this;
    arr.each(function(obj) {
      return self.push(obj);
    });
    self.$.root = root;
    self.$.keyed = keyed;
  },

  _get: function( key ) {
    var self=this;
    if (self.$.keyed) {
      return self.find(function(obj) {
        return obj.name() == key;
      });
    } else {
      return self.at(key);
    }
  },

  has_key_p: function( key ) {
    var self=this;
    return self._get(key);
  },

  joinXXX: function( block, other ) {
    var self=this;
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

  keys: function( ) {
    var self=this;
    if (self.$.keyed) {
      return self.map(function(o) {
        return o.name();
      });
    } else {
      return null;
    }
  }
});

load_path = function(path) {
  return load(System.readJSON(path));
}

load = function(doc) {
  ss0 = make_object(doc, null);
  return ss0; return Copy(ManagedData.new(ss0), ss0);
}

make_object = function(data, root) {
  if (data._get("class") == "Schema") {
    return makeProxy(Schema.new(data, root));
  } else if (data._get("class") == "Class") {
    return makeProxy(Class.new(data, root));
  } else {
    return makeProxy(MObject.new(data, root));
  }
}

make_field = function(data, root, keyed) {
  if (data.is_a_p(Array)) {
    return make_many(data, root, keyed);
  } else {
    return get_object(data, root);
  }
}

get_object = function(data, root) {
  if (! data) {
    return null;
  } else if (data.is_a_p(String)) {
    return Paths.parse(data).deref(root);
  } else {
    return make_object(data, root);
  }
}

make_many = function(data, root, keyed) {
  arr = data.map(function(a) {
    return get_object(a, root);
  });
  return BootManyField.new(arr, root, keyed);
}

Boot = { make_field: make_field };

 x = load_path("/Users/wcook/enso/src/core/system/boot/schema_schema.json");
console.log("x._id = " + x._id()) ;
console.log("List = " + x.types().map(function(x) {return x.to_s()}));
console.log("Test = " + x.types()._get("Primitive").name()) ;
console.log("Test = " + x.types()._get("Primitive").to_s()) ;
 