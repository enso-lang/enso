define([
  "core/system/utils/paths",
  "core/schema/code/factory",
  "json",
  "enso"
],
function(Paths, Factory, Json, Enso) {

  var Boot ;

  var MObject = MakeClass( EnsoProxyObject, {
    _class_: {
      seq_no: 0
    },

    _id: function() { return this.$._id },

    factory: function() { return this.$.factory },
    set_factory: function(val) { this.$.factory  = val },

    _path: function() { return this.$._path },
    set__path: function(val) { this.$._path  = val },

    file_path: function() { return this.$.file_path },

    initialize: function(data, root) {
      var self = this; 
      var super$ = this.super$.initialize;
      self.$._id = self._class_.seq_no = self._class_.seq_no + 1;
      self.$.data = data;
      self.$.root = root || self;
      self.$.factory = self;
      self.$.file_path = [];
      return self.$.fields = new EnsoHash ( { } );
    },

    schema_class: function() {
      var self = this; 
      var super$ = this.super$.schema_class;
      return self.$.root.types()._get(self.$.data._get("class"));
    },

    _get: function(sym) {
      var self = this; 
      var val;
      var super$ = this.super$._get;
      val = self.$.fields._get(sym);
      if (val) {
        return val;
      } else {
        return self.$.fields ._set( sym , sym._get(- 1) == "?"
          ? self.schema_class().name() == sym.slice(0, sym.length() - 1)
          : self.$.data.has_key_P(S(sym, "="))
            ? self.$.data._get(S(sym, "="))
            : self.$.data.has_key_P(S(sym, "#"))
              ? Boot.make_field(self.$.data._get(S(sym, "#")), self.$.root, true)
              : self.$.data.has_key_P(sym.to_s())
                ? Boot.make_field(self.$.data._get(sym.to_s()), self.$.root, false)
                : System.raise(S("Trying to deref nonexistent field ", sym, " in ", self.$.data.to_s().slice(0, 300)))
        );
      }
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.name || (self.$.name = ((function(){ {
        try {
          return S("<", self.$.data._get("class"), " ", self._id(), " ", self.name(), ">");
        } catch ( DUMMY ) {
          return S("<", self.$.data._get("class"), " ", self._id(), ">");
        }
      } })()));
    }
  });

  var Schema = MakeClass( MObject, {
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

  var Class = MakeClass( MObject, {
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

  var BootManyField = MakeClass( Array, {
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

  Boot = {
    load_path: function(path) {
      return Boot.load(System.readJSON(path)._get("model"));
    } ,

    load: function(doc) {
      ss0 = Boot.make_object(doc, null);
      return Copy(ManagedData.new(ss0), ss0);
    } ,

    make_object: function(data, root) {
      if (data._get("class") == "Schema") {
        return Schema.new(data, root);
      } else if (data._get("class") == "Class") {
        return Class.new(data, root);
      } else {
        return MObject.new(data, root);
      }
    } ,

    make_field: function(data, root, keyed) {
      if (data.is_a_P(Array)) {
        return Boot.make_many(data, root, keyed);
      } else {
        return Boot.get_object(data, root);
      }
    } ,

    get_object: function(data, root) {
      if (! data) {
        return null;
      } else if (data.is_a_P(String)) {
        return Paths.parse(data).deref(root);
      } else {
        return Boot.make_object(data, root);
      }
    } ,

    make_many: function(data, root, keyed) {
      arr = data.map(function(a) {
        return Boot.get_object(a, root);
      });
      return BootManyField.new(arr, root, keyed);
    } ,

    MObject: MObject,
    Schema: Schema,
    Class: Class,
    BootManyField: BootManyField,

  };
  return Boot;
})
