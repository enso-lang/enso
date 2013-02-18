define([
  "json",
  "enso"
],
function(Json, Enso) {

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
      var has_name, keyed, name;
      var super$ = this.super$.initialize;
      self.$._id = self._class_.seq_no = self._class_.seq_no + 1;
      self.$.factory = self;
      self.$.file_path = [];
      self.$.root = root || self;
      self.$.data = data;
      has_name = false;
      data.each(function(key, value) {
        if (key == "class") {
        } else if (key._get(- 1) == "=") {
          self.define_singleton_value(key.slice(0, key.length - 1), value);
          if (key == "name=") {
            has_name = true;
            return self.define_singleton_value("to_s", S("<", data._get("class"), " ", self._id(), " ", value, ">"));
          }
        } else if (System.test_type(value, Array)) {
          keyed = key._get(- 1) == "#";
          name = keyed
            ? key.slice(0, key.length - 1)
            : key
          ;
          if (value.length == 0 || ! System.test_type(value._get(0), String)) {
            return self._create_many(name, value.map(function(a) {
              return Boot.make_object(a, self.$.root);
            }), keyed);
          }
        } else if (! System.test_type(value, String)) {
          return self.define_singleton_value(key, Boot.make_object(value, self.$.root));
        }
      });
      if (! has_name) {
        return self.define_singleton_value("to_s", S("<", data._get("class"), " ", self._id(), ">"));
      }
    },

    _complete: function() {
      var self = this; 
      var keyed, name;
      var super$ = this.super$._complete;
      self.$.data.each(function(key, value) {
        if (key == "class") {
          return self.define_singleton_value("schema_class", self.$.root.types()._get(value));
        } else if (key._get(- 1) != "=" && value) {
          if (System.test_type(value, Array)) {
            keyed = key._get(- 1) == "#";
            name = keyed
              ? key.slice(0, key.length - 1)
              : key
            ;
            if (value.length > 0 && System.test_type(value._get(0), String)) {
              return self._create_many(name, value.map(function(a) {
                return Paths.parse(a).deref(self.$.root);
              }), keyed);
            } else {
              return self._get(name).each(function(obj) {
                return obj._complete();
              });
            }
          } else if (System.test_type(value, String)) {
            return self.define_singleton_value(key, Paths.parse(value).deref(self.$.root));
          } else {
            return self._get(key)._complete();
          }
        }
      });
      return self.$.root.types().each(function(cls) {
        return self.define_singleton_value(S(cls.name(), "?"), self.$.data._get("class") == cls.name());
      });
    },

    _create_many: function(name, arr, keyed) {
      var self = this; 
      var super$ = this.super$._create_many;
      return self.define_singleton_value(name, BootManyField.new(arr, self.$.root, keyed));
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
        console.log("  MATCH " + self.$.keyed + ": " + this + "--" + other);
      if (self.$.keyed) {
        other = other || new EnsoHash ( { } );
        ks = self.keys().union(other.keys());
        return ks.each(function(k) {
          return block.call(self._get(k), other._get(k));
        });
      } else {
        a = Array(self);
        b = Array(other);
        return Range.new(0, [a.length, b.length].max() - 1).each(function(i) {
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
      ss0._complete();
      return ss0; return Copy(ManagedData.new(ss0), ss0);
    } ,

    make_object: function(data, root) {
      if (data != null) {
        if (data._get("class") == "Schema") {
          return Schema.new(data, root);
        } else if (data._get("class") == "Class") {
          return Class.new(data, root);
        } else {
          return MObject.new(data, root);
        }
      }
    } ,

    MObject: MObject,
    Schema: Schema,
    Class: Class,
    BootManyField: BootManyField,

  };
  return Boot;
})
