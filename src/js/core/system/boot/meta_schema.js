'use strict'

//// MetaSchema ////

var cwd = process.cwd() + '/';
var Factory = require(cwd + "core/schema/code/factory.js");
var Union = require(cwd + "core/schema/tools/union.js");
var Enso = require(cwd + "enso.js");

var MetaSchema;

var load_path = function(path) {
  var self = this, json, result;
  json = Enso.System.readJSON(path);
  result = MetaSchema.load_doc(json.get$("model"));
  result.factory().file_path() .set$(0, json.get$("source"));
  return result;
};

var load_doc = function(doc) {
  var self = this, ss0, factory;
  ss0 = MetaSchema.make_object(doc, null);
  factory = Factory.make(ss0);
  ss0._complete(factory);
  return ss0;
};

var make_object = function(data, root) {
  var self = this, schema, klass, obj;
  if (data != null) {
    switch (data.get$("class")) {
      case "Schema":
        if (root != null) {
          MetaSchema.raise("INVALID Schema root");
        }
        schema = Schema.new();
        schema.setup(data, schema);
        return schema;
      case "Class":
        klass = Class.new();
        klass.setup(data, root);
        return klass;
      default:
        obj = MObject.new();
        obj.setup(data, root);
        return obj;
    }
  }
};

var path_eval = function(str, obj) {
  var self = this, n, field, obj, index;
  str.split_M(".").each(function(part) {
    n = part.index("[");
    if (n > 0 && part.end_with_P("]")) {
      field = part.slice_M(0, n);
      obj = obj.get$(field);
      index = part.slice_M(n + 1, (part.size_M() - n) - 2);
      return obj = obj.get$(index);
    } else {
      return obj = obj.get$(part);
    }
  });
  return obj;
};

class MObject extends Enso.EnsoProxyObject {
  static new(...args) { return new MObject(...args) };

  static seq_no = 0;

  identity() { return this.identity$ };

  factory() { return this.factory$ };
  set_factory(val) { this.factory$ = val };

  _path() { return this._path$ };
  set__path(val) { this._path$ = val };

  file_path() { return this.file_path$ };

  _id() {
    var self = this;
    return self.identity$;
  };

  setup(data, root) {
    var self = this, has_name, keyed, name;
    self.identity$ = this.constructor.seq_no$$ = this.constructor.seq_no$$ + 1;
    self.factory$ = null;
    self.file_path$ = [];
    self.root$ = root;
    self.data$ = data;
    has_name = false;
    data.each(function(key, value) {
      if (key == "class") {
      } else if (key.end_with_P("=")) {
        self.define_singleton_value(key.slice_M(0, key.size_M() - 1), value);
        if (key == "name=") {
          has_name = true;
          return self.define_singleton_value("to_s", Enso.S("<", data.get$("class"), " ", value, ">"));
        }
      } else if (Enso.System.test_type(value, Array)) {
        keyed = key.end_with_P("#");
        name = keyed
          ? key.slice_M(0, key.size_M() - 1)
          : key;
        if (value.size_M() == 0 || ! Enso.System.test_type(value.get$(0), String)) {
          return self._create_many(name, value.map(function(a) {
            return MetaSchema.make_object(a, self.root$);
          }), keyed);
        }
      } else if (! Enso.System.test_type(value, String)) {
        return self.define_singleton_value(key, MetaSchema.make_object(value, self.root$));
      }
    });
    if (! has_name) {
      return self.define_singleton_value("to_s", Enso.S("<", data.get$("class"), ">"));
    }
  };

  _lookup(str, obj) {
    var self = this, n, field, obj, index;
    str.split_M(".").each(function(part) {
      if ((n = part.index("[")) && part.end_with("]")) {
        field = part.slice_M(0, n);
        obj = obj.get$(field);
        index = part.slice_M(n + 1, (part.size_M() - n) - 2);
        return obj = obj.get$(index);
      } else {
        return obj = obj.get$(part);
      }
    });
    return obj;
  };

  _complete(factory) {
    var self = this, keyed, name;
    self.set_factory(factory);
    return self.data$.each(function(key, value) {
      if (key == "class") {
        self.define_singleton_value("schema_class", self.root$.types().get$(value));
        return self.define_singleton_method(function(type) {
          return type == value;
        }, "is_a?");
      } else if (! key.end_with_P("=") && value != null) {
        if (Enso.System.test_type(value, Array)) {
          keyed = key.end_with_P("#");
          name = keyed
            ? key.slice_M(0, key.size_M() - 1)
            : key;
          if (value.size_M() > 0 && Enso.System.test_type(value.get$(0), String)) {
            return self._create_many(name, value.map(function(a) {
              return MetaSchema.path_eval(a, self.root$);
            }), keyed);
          } else {
            return self.get$(name).each(function(obj) {
              return obj._complete(factory);
            });
          }
        } else if (Enso.System.test_type(value, String)) {
          return self.define_singleton_value(key, MetaSchema.path_eval(value, self.root$));
        } else {
          return self.get$(key)._complete(factory);
        }
      }
    });
  };

  _create_many(name, arr, keyed) {
    var self = this;
    return self.define_singleton_value(name, BootManyField.new(arr, keyed));
  };
};

class Schema extends MObject {
  static new(...args) { return new Schema(...args) };

  classes() {
    var self = this;
    return BootManyField.new(self.types().select(function(t) {
      return Enso.System.test_type(t, "Class");
    }), true);
  };

  primitives() {
    var self = this;
    return BootManyField.new(self.types().select(function(t) {
      return Enso.System.test_type(t, "Primitive");
    }), true);
  };
};

class Class extends MObject {
  static new(...args) { return new Class(...args) };

  Class_P() {
    var self = this;
    return true;
  };

  all_fields() {
    var self = this;
    return BootManyField.new(self.supers().flat_map(function(s) {
      return s.all_fields();
    }).concat(self.defined_fields()), true);
  };

  fields() {
    var self = this;
    return BootManyField.new(self.all_fields().select(function(f) {
      return ! f.computed();
    }), true);
  };

  key() {
    var self = this;
    return self.fields().find(function(f) {
      return f.key();
    });
  };
};

class BootManyField extends Enso.mix(Array, Enso.Enumerable) {
  static new(...args) { return new BootManyField(...args) };

  constructor(arr, keyed) {
    super();
    var self = this;
    arr.each(function(obj) {
      return self.push(obj);
    });
    self.keyed$ = keyed;
  };

  get$(key) {
    var self = this;
    if (self.keyed$) {
      return self.find(function(obj) {
        return obj.name() == key;
      });
    } else {
      return self.at(key);
    }
  };

  has_key_P(key) {
    var self = this;
    return self.get$(key);
  };

  each_with_match(block, other) {
    var self = this, other, ks, i;
    if (self.keyed$) {
      other = other || Enso.EMap.new();
      ks = self.keys() || other.keys();
      return ks.each(function(k) {
        return block(self.get$(k), other.get$(k));
      });
    } else {
      i = 0;
      return self.each(function(a) {
        block(a, other && other.get$(i));
        return i = i + 1;
      });
    }
  };

  keys() {
    var self = this;
    if (self.keyed$) {
      return self.map(function(o) {
        return o.name();
      });
    } else {
      return null;
    }
  };
};

MetaSchema = {
  load_path: load_path,
  load_doc: load_doc,
  make_object: make_object,
  path_eval: path_eval,
  MObject: MObject,
  Schema: Schema,
  Class: Class,
  BootManyField: BootManyField,
};
module.exports = MetaSchema ;
