define(["core/schema/code/factory", "core/schema/tools/union", "enso"], (function (Factory, Union, Enso) {
  var MetaSchema;
  var MObject = MakeClass("MObject", EnsoProxyObject, [], (function () {
    (this.$.seq_no = 0);
  }), (function (super$) {
    (this._id = (function () {
      return this.$._id;
    }));
    (this.factory = (function () {
      return this.$.factory;
    }));
    (this.set_factory = (function (val) {
      (this.$.factory = val);
    }));
    (this._path = (function () {
      return this.$._path;
    }));
    (this.set__path = (function (val) {
      (this.$._path = val);
    }));
    (this.file_path = (function () {
      return this.$.file_path;
    }));
    undefined;
    (this.initialize = (function (data, root) {
      var self = this;
      var has_name;
      (self.$._id = (self._class_.$.seq_no = (self._class_.$.seq_no + 1)));
      (self.$.factory = self);
      (self.$.file_path = []);
      (self.$.root = (root || self));
      (self.$.data = data);
      (has_name = false);
      data.each((function (key, value) {
        var name, keyed;
        if ((key == "class")) {
        }
        else {
          if ((key._get((-1)) == "=")) {
            self.define_singleton_value(key.slice(0, (key.size() - 1)), value);
            if ((key == "name=")) {
              (has_name = true);
              return self.define_singleton_value("to_s", S("<", data._get("class"), " ", self._id(), " ", value, ">"));
            }
          }
          else {
            if (System.test_type(value, Array)) {
              (keyed = (key._get((-1)) == "#"));
              (name = (function () {
                if (keyed) { 
                  return key.slice(0, (key.size() - 1)); 
                }
                else { 
                  return key;
                }
              })());
              if (((value.size() == 0) || (!System.test_type(value._get(0), String)))) {
                return self._create_many(name, value.map((function (a) {
                  return MetaSchema.make_object(a, self.$.root);
                })), keyed);
              }
            }
            else {
              if ((!System.test_type(value, String))) { 
                return self.define_singleton_value(key, MetaSchema.make_object(value, self.$.root)); 
              } 
              else {
                   }
            }
          }
        }
      }));
      if ((!has_name)) {
        return self.define_singleton_value("to_s", S("<", data._get("class"), " ", self._id(), ">"));
      }
    }));
    (this._lookup = (function (str, obj) {
      var self = this;
      str.split(".").each((function (part) {
        var n, index, field;
        if (((n = part.index("[")) && (part.slice((-1)) == "]"))) {
          (field = part.slice(0, n));
          (obj = obj._get(field));
          (index = part.slice((n + 1), ((part.size() - n) - 2)));
          return (obj = obj._get(index));
        }
        else {
          return (obj = obj._get(part));
        }
      }));
      return obj;
    }));
    (this._complete = (function () {
      var self = this;
      self.$.data.each((function (key, value) {
        var name, keyed;
        if ((key == "class")) { 
          return self.define_singleton_value("schema_class", self.$.root.types()._get(value)); 
        }
        else { 
          if (((key._get((-1)) != "=") && (value != null))) { 
            if (System.test_type(value, Array)) {
              (keyed = (key._get((-1)) == "#"));
              (name = (function () {
                if (keyed) { 
                  return key.slice(0, (key.size() - 1)); 
                }
                else { 
                  return key;
                }
              })());
              if (((value.size() > 0) && System.test_type(value._get(0), String))) { 
                return self._create_many(name, value.map((function (a) {
                  return MetaSchema.path_eval(a, self.$.root);
                })), keyed); 
              }
              else { 
                return self._get(name).each((function (obj) {
                  return obj._complete();
                }));
              }
            }
            else {
              if (System.test_type(value, String)) { 
                return self.define_singleton_value(key, MetaSchema.path_eval(value, self.$.root)); 
              }
              else { 
                return self._get(key)._complete();
              }
            } 
          } 
          else {
               }
        }
      }));
      return self.$.root.types().each((function (cls) {
        return self.define_singleton_value(S("", cls.name(), "?"), (self.$.data._get("class") == cls.name()));
      }));
    }));
    (this._create_many = (function (name, arr, keyed) {
      var self = this;
      return self.define_singleton_value(name, BootManyField.new(arr, self.$.root, keyed));
    }));
  }));
  var Schema = MakeClass("Schema", MObject, [], (function () {
  }), (function (super$) {
    (this.classes = (function () {
      var self = this;
      return BootManyField.new(self.types().select((function (t) {
        return t.Class_P();
      })), self.$.root, true);
    }));
    (this.primitives = (function () {
      var self = this;
      return BootManyField.new(self.types().select((function (t) {
        return t.Primitive_P();
      })), self.$.root, true);
    }));
  }));
  var Class = MakeClass("Class", MObject, [], (function () {
  }), (function (super$) {
    (this.all_fields = (function () {
      var self = this;
      return BootManyField.new(self.supers().flat_map((function (s) {
        return s.all_fields();
      })).concat(self.defined_fields()), self.$.root, true);
    }));
    (this.fields = (function () {
      var self = this;
      return BootManyField.new(self.all_fields().select((function (f) {
        return (!f.computed());
      })), self.$.root, true);
    }));
    (this.key = (function () {
      var self = this;
      return self.fields().find((function (f) {
        return f.key();
      }));
    }));
  }));
  var BootManyField = MakeClass("BootManyField", Array, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (arr, root, keyed) {
      var self = this;
      arr.each((function (obj) {
        return self.push(obj);
      }));
      (self.$.root = root);
      return (self.$.keyed = keyed);
    }));
    (this._get = (function (key) {
      var self = this;
      if (self.$.keyed) { 
        return self.find((function (obj) {
          return (obj.name() == key);
        })); 
      }
      else { 
        return self.at(key);
      }
    }));
    (this.has_key_P = (function (key) {
      var self = this;
      return self._get(key);
    }));
    (this.each_with_match = (function (block, other) {
      var self = this;
      var ks, i;
      if (self.$.keyed) {
        (other = (other || (new EnsoHash({
          
        }))));
        (ks = (self.keys() || other.keys()));
        return ks.each((function (k) {
          return block(self._get(k), other._get(k));
        }));
      } else {
        (i = 0);
        return self.each((function (a) {
          block(a, (other && other._get(i)));
          return (i = (i + 1));
        }));
      }
    }));
    (this.keys = (function () {
      var self = this;
      if (self.$.keyed) { 
        return self.map((function (o) {
          return o.name();
        })); 
      }
      else { 
        return null;
      }
    }));
  }));
  (MetaSchema = {
    Schema: Schema,
    load: (function (doc) {
      var self = this;
      var ss0;
      (ss0 = self.make_object(doc, null));
      ss0._complete();
      return Union.Copy(Factory.new(ss0), ss0);
    }),
    BootManyField: BootManyField,
    MObject: MObject,
    make_object: (function (data, root) {
      var self = this;
      if ((data != null)) {
        switch ((function () {
          return data._get("class");
        })()) {
          case "Class":
           return Class.new(data, root);
          case "Schema":
           return Schema.new(data, root);
          default:
           return MObject.new(data, root);
        }
            
      }
    }),
    path_eval: (function (str, obj) {
      var self = this;
      str.split(".").each((function (part) {
        var n, index, field;
        if (((n = part.index("[")) && (part.slice((-1)) == "]"))) {
          (field = part.slice(0, n));
          (obj = obj._get(field));
          (index = part.slice((n + 1), ((part.size() - n) - 2)));
          return (obj = obj._get(index));
        }
        else {
          return (obj = obj._get(part));
        }
      }));
      return obj;
    }),
    Class: Class,
    load_path: (function (path) {
      var self = this;
      var json, result;
      (json = System.readJSON(path));
      (result = self.load(json._get("model")));
      result.factory().file_path()._set(0, json._get("source"));
      return result;
    })
  });
  return MetaSchema;
}));