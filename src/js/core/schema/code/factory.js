'use strict'

//// Factory ////

var cwd = process.cwd() + '/';
var Schemapath = require(cwd + "core/system/utils/schemapath.js");
var Schema = require(cwd + "core/system/library/schema.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Impl = require(cwd + "core/expr/code/impl.js");
var Env = require(cwd + "core/expr/code/env.js");
var Freevar = require(cwd + "core/expr/code/freevar.js");
var Enso = require(cwd + "enso.js");
var Dynamic = require(cwd + "core/schema/code/dynamic.js");

var Factory;

var make = function(schema) {
  var self = this;
  return SchemaFactory.new(schema);
};

class SchemaFactory extends Enso.EnsoBaseClass {
  static new(...args) { return new SchemaFactory(...args) };

  schema() { return this.schema$ };

  file_path() { return this.file_path$ };
  set_file_path(val) { this.file_path$ = val };

  constructor(schema) {
    super();
    var self = this;
    self.schema$ = schema;
    self.roots$ = [];
    self.file_path$ = [];
    self.__install_methods(self.schema$);
    self.__check_cylic_inheritance(self.schema$);
  };

  __install_methods(schema) {
    var self = this;
    return schema.classes().each(function(klass) {
      return self.define_singleton_method(function(...args) {
        return MObject.new(klass, self, ...args);
      }, klass.name());
    });
  };

  __check_cylic_inheritance(schema) {
    var self = this;
    return schema.classes().each(function(c) {
      if (self.__check_cyclic_subtyping(c, [])) {
        return self.raise(Enso.S("Build factory failed: ", c, " is its own superclass"));
      }
    });
  };

  __check_cyclic_subtyping(c, subs) {
    var self = this, res;
    if (subs.include_P(c)) {
      return true;
    } else {
      res = false;
      c.supers().each(function(s) {
        return res = res || self.__check_cyclic_subtyping(s, subs.union([c]));
      });
      return res;
    }
  };

  unsafe_P() {
    var self = this;
    return ! (self.unsafe$ == null) && self.unsafe$ > 0;
  };

  unsafe_mode(body) {
    var self = this;
    self.unsafe$ = self.unsafe$
      ? self.unsafe$ + 1
      : 1;
    body();
    return self.unsafe$ = self.unsafe$ - 1;
  };

  get$(name) {
    var self = this;
    return self.send(name);
  };

  register(root) {
    var self = this;
    return self.root$ = root;
  };

  __delete_obj(mobj) {
    var self = this;
    return self.root$.__delete_obj(mobj);
  };
};

class IDCounterClass {
  static new(...args) { return new IDCounterClass(...args) };

  constructor() {
    var self = this;
    self.id$ = 0;
  };

  next() {
    var self = this;
    self.id$ = self.id$ + 1;
    return self.id$;
  };
};

var IDCounter = IDCounterClass.new();

class MObject extends Enso.EnsoProxyObject {
  static new(...args) { return new MObject(...args) };

  _origin() { return this._origin$ };
  set__origin(val) { this._origin$ = val };

  factory() { return this.factory$ };

  extra_instance_data() { return this.extra_instance_data$ };
  set_extra_instance_data(val) { this.extra_instance_data$ = val };

  props() { return this.props$ };

  identity() { return this.identity$ };

  _id() {
    var self = this;
    return self.identity$;
  };

  constructor(klass, factory, ...args) {
    super();
    var self = this;
    self.identity$ = IDCounter.next();
    self.listeners$ = Enso.EMap.new();
    self.props$ = Enso.EMap.new();
    self.path$ = null;
    self.define_singleton_value("schema_class", klass);
    self.setupFromSchema(klass, factory, args);
  };

  setupFromSchema(klass, factory, args) {
    var self = this;
    self.factory$ = factory;
    self.define_singleton_method(function(type) {
      return type == klass.name();
    }, "is_a?");
    self.__to_s(klass);
    klass.all_fields().each(function(fld) {
      return self.__setup(fld);
    });
    return klass.fields().each_with_index(function(fld, i) {
      if (i < args.size_M()) {
        if (fld.many()) {
          return args.get$(i).each(function(value) {
            return self.get$(fld.name()).push(value);
          });
        } else {
          return self .set$(fld.name(), args.get$(i));
        }
      }
    });
  };

  __setup(fld) {
    var self = this, prop, key, collection;
    if (fld.computed()) {
      return self.__computed(fld);
    } else if (! fld.many()) {
      if (Enso.System.test_type(fld.type(), "Primitive")) {
        prop = Prim.new(self, fld);
      } else {
        prop = Ref.new(self, fld);
      }
      self.props$ .set$(fld.name(), prop);
      self.define_getter(fld.name(), prop);
      return self.define_setter(fld.name(), prop);
    } else {
      if (key = fld.type().key()) {
        collection = Set.new(self, fld, key);
      } else {
        collection = List.new(self, fld);
      }
      self.props$ .set$(fld.name(), collection);
      return self.define_singleton_value(fld.name(), collection);
    }
  };

  __get(name) {
    var self = this;
    return self.props$.get$(name);
  };

  __to_s(cls) {
    var self = this, k;
    k = cls.key() || cls.fields().find(function(f) {
      return Enso.System.test_type(f.type(), "Primitive");
    });
    if (k) {
      return self.define_singleton_method(function() {
        return Enso.S("<<", cls.name(), " ", self.identity(), " '", self.get$(k.name()), "'>>");
      }, "to_s");
    } else {
      return self.define_singleton_value("to_s", Enso.S("<<", cls.name(), " ", self.identity(), ">>"));
    }
  };

  inspect() {
    var self = this;
    return self.to_s();
  };

  __computed(fld) {
    var self = this, c, base, name, exp, fvInterp, val, fvs, key, collection;
    if (Enso.System.test_type(fld.computed(), "EList") && (c = fld.owner().supers().find(function(c) {
      return c.all_fields().get$(fld.name());
    }))) {
      base = c.all_fields().get$(fld.name());
      if (base.inverse()) {
        fld.computed().elems().each(function(v) {
          if (! Enso.System.test_type(v, "EVar")) {
            self.raise(Enso.S("Field override ", fld.name(), " includes non-var ", v));
          }
          return self.__get(v.name()).set__set_inverse(base.inverse());
        });
      }
    }
    name = fld.name();
    exp = fld.computed();
    fvInterp = Freevar.FreeVarExprC.new();
    val = null;
    return self.define_singleton_method(function() {
      if (val == null) {
        fvs = fvInterp.dynamic_bind(function() {
          return fvInterp.depends(exp);
        }, Enso.EMap.new({env: Env.ObjEnv.new(self), bound: []}));
        fvs.each(function(fv) {
          if (fv.object()) {
            return fv.object().add_listener(function() {
              return val = null;
            }, fv.index());
          }
        });
        val = Impl.eval_M(exp, Enso.EMap.new({env: Env.ObjEnv.new(self)}));
        if (fld.many()) {
          if (key = fld.type().key()) {
            collection = Set.new(self, fld, key);
          } else {
            collection = List.new(self, fld);
          }
          val.each(function(v) {
            return collection.push(v);
          });
          val = collection;
        }
        val;
      }
      return val;
    }, name);
  };

  graph_identity() {
    var self = this;
    return self.factory$;
  };

  delete_in_place() {
    var self = this;
    return self.factory$.__delete_obj(self);
  };

  __delete_obj(mobj) {
    var self = this;
    return self.schema_class().fields().each(function(fld) {
      if (fld.traversal()) {
        return self.__get(fld.name()).__delete_obj(mobj);
      }
    });
  };

  dynamic_update() {
    var self = this;
    return self.dyn$ = self.dyn$ || Dynamic.DynamicUpdateProxy.new(self);
  };

  add_listener(block, name) {
    var self = this, listeners;
    listeners = self.listeners$.get$(name);
    if (! listeners) {
      listeners = [];
      self.listeners$ .set$(name, listeners);
    }
    return listeners.push(block);
  };

  notify(name, val) {
    var self = this;
    if (self.listeners$.get$(name)) {
      return self.listeners$.get$(name).each(function(blk) {
        return blk(val);
      });
    }
  };

  __shell() {
    var self = this;
    return self.__shell$;
  };

  set___shell(nval) {
    var self = this;
    return self.__shell$ = nval;
  };

  _origin_of(name) {
    var self = this;
    return self.__get(name)._origin();
  };

  _set_origin_of(name, org) {
    var self = this;
    return self.__get(name).set__origin(org);
  };

  _path_of(name) {
    var self = this;
    return self._path().field(name);
  };

  _path() {
    var self = this;
    if (self.path$ == null) {
      self.path$ = self.__shell()
        ? self.__shell()._path(self)
        : Schemapath.Path.new();
    }
    return self.path$;
  };

  __clean_path() {
    var self = this;
    self.path$ = null;
    return self.schema_class().fields().each(function(fld) {
      if (fld.traversal()) {
        return self.__get(fld.name()).__clean_path();
      }
    });
  };

  _clone() {
    var self = this, r;
    r = MObject.new(self.schema_class(), self.factory$);
    self.schema_class().fields().each(function(field) {
      if (field.many()) {
        return self.get$(field.name()).each(function(o) {
          return r.get$(field.name()).push(o);
        });
      } else {
        return r .set$(field.name(), self.get$(field.name()));
      }
    });
    return r;
  };

  eql_P(o) {
    var self = this;
    return self == o;
  };

  equals(o) {
    var self = this;
    return (o && Enso.System.test_type(o, MObject)) && self.identity() == o.identity();
  };

  hash() {
    var self = this;
    return self.identity$;
  };

  finalize() {
    var self = this;
    self.factory$.register(self);
    return self;
  };
};

class Field extends Enso.EnsoBaseClass {
  static new(...args) { return new Field(...args) };

  _origin() { return this._origin$ };
  set__origin(val) { this._origin$ = val };

  constructor(owner, field) {
    super();
    var self = this;
    self.owner$ = owner;
    self.field$ = field;
    if (field) {
      self.inverse$ = field.inverse();
    }
  };

  set__set_inverse(inv) {
    var self = this;
    if (self.inverse$) {
      self.raise(Enso.S("Overiding inverse of field '", inv.owner().name(), ".", self.invk().name(), "'"));
    }
    return self.inverse$ = inv;
  };

  __delete_obj(mobj) {
    var self = this;
  };

  to_s() {
    var self = this;
    return Enso.S(".", self.field$.name(), " = ", self.value$);
  };
};

class Single extends Field {
  static new(...args) { return new Single(...args) };

  constructor(owner, field) {
    super(owner, field);
    var self = this;
    self.value$ = self.defaultValue();
  };

  set(value) {
    var self = this;
    self.check(value);
    self.value$ = value;
    return self.owner$.notify(self.field$.name(), value);
  };

  get() {
    var self = this;
    return self.value$;
  };

  init(value) {
    var self = this;
    return self.set(value);
  };

  defaultValue() {
    var self = this;
    return null;
  };
};

class Prim extends Single {
  static new(...args) { return new Prim(...args) };

  check(value) {
    var self = this, ok;
    if (! self.field$.optional() || ! (value == null)) {
      ok = ((function() {
        switch (self.field$.type().name()) {
          case "str":
            return Enso.System.test_type(value, String);
          case "int":
            return Enso.System.test_type(value, Enso.Integer);
          case "bool":
            return Enso.System.test_type(value, Enso.TrueClass) || Enso.System.test_type(value, Enso.FalseClass);
          case "real":
            return Enso.System.test_type(value, Enso.Numeric);
          case "datetime":
            return Enso.System.test_type(value, DateTime);
          case "atom":
            return ((Enso.System.test_type(value, Enso.Numeric) || Enso.System.test_type(value, String)) || Enso.System.test_type(value, Enso.TrueClass)) || Enso.System.test_type(value, Enso.FalseClass);
        }
      })());
      if (! ok) {
        return self.raise(Enso.S("Invalid value for ", self.field$.name(), ":", self.field$.type().name(), " = ", value));
      }
    }
  };

  defaultValue() {
    var self = this;
    if (! self.field$.optional()) {
      switch (self.field$.type().name()) {
        case "str":
          return "";
        case "int":
          return 0;
        case "bool":
          return false;
        case "real":
          return 0.0;
        case "datetime":
          return DateTime.now();
        case "atom":
          return null;
        default:
          return self.raise(Enso.S("Unknown primitive type: ", self.field$.type().name()));
      }
    }
  };
};

function SetUtils(parent) {
  return class extends parent {
    to_ary() {
      var self = this;
      return self.value$.values();
    };

    union(other) {
      var self = this, result;
      result = Set.new(null, self.field$, self.__key() || other.__key());
      self.each(function(x) {
        return result.push(x);
      });
      other.each(function(x) {
        return result.push(x);
      });
      return result;
    };

    select(block) {
      var self = this, result;
      result = Set.new(null, self.field$, self.__key());
      self.each(function(elt) {
        if (block(elt)) {
          return result.push(elt);
        }
      });
      return result;
    };

    flat_map(block) {
      var self = this, new_V, set, key;
      new_V = null;
      self.each(function(x) {
        set = block(x);
        if (new_V == null) {
          key = set.__key();
          new_V = Set.new(null, self.field$, key);
        }
        return set.each(function(y) {
          return new_V.push(y);
        });
      });
      return new_V || Set.new(null, self.field$, self.__key());
    };

    hash_map(block) {
      var self = this, new_V;
      new_V = Enso.EMap.new();
      self.each(function(v) {
        return new_V .set$(v.get$(self.__key().name()), block(v));
      });
      return new_V;
    };

    each_with_match(block, other) {
      var self = this, empty;
      empty = Set.new(null, self.field$, self.__key());
      return self.__outer_join(function(sa, sb) {
        if ((sa && sb) && sa.get$(self.__key().name()) == sb.get$(self.__key().name())) {
          return block(sa, sb);
        } else if (sa) {
          return block(sa, null);
        } else if (sb) {
          return block(null, sb);
        }
      }, other || empty);
    };

    __key() {
      var self = this;
      return self.key$;
    };

    __keys() {
      var self = this;
      return self.value$.keys();
    };

    __outer_join(block, other) {
      var self = this, keys;
      keys = self.__keys().union(other.__keys());
      return keys.each(function(key) {
        return block(self.get$(key), other.get$(key), key);
      });
    }; }};

function ListUtils(parent) {
  return class extends Enso.mix(parent, Enso.Enumerable) {
    each_with_match(block, other) {
      var self = this;
      if (! self.empty_P()) {
        return self.each(function(item) {
          return block(item, null);
        });
      }
    };

    flat_map(block) {
      var self = this, new_V, set;
      new_V = List.new(null, self.field$);
      self.each(function(x) {
        set = block(x);
        return set.each(function(y) {
          return new_V.push(y);
        });
      });
      return new_V;
    }; }};

function RefHelpers(parent) {
  return class extends parent {
    notify(old, new_V) {
      var self = this;
      if (old != new_V) {
        self.owner$.notify(self.field$.name(), new_V);
        if (self.inverse$) {
          if (self.inverse$.many()) {
            if (old) {
              old.__get(self.inverse$.name()).__delete(self.owner$);
            }
            if (new_V) {
              return new_V.__get(self.inverse$.name()).__insert(self.owner$);
            }
          } else {
            if (old) {
              old.__get(self.inverse$.name()).__set(null);
            }
            if (new_V) {
              return new_V.__get(self.inverse$.name()).__set(self.owner$);
            }
          }
        }
      }
    };

    check(mobj) {
      var self = this;
      if (! self.owner$.graph_identity().unsafe_P()) {
        if (mobj || ! self.field$.optional()) {
          if (mobj == null) {
            self.raise(Enso.S("Cannot assign nil to non-optional field '", self.field$.owner().name(), ".", self.field$.name(), "'"));
          }
          if (! Schema.subclass_P(mobj.schema_class(), self.field$.type())) {
            self.raise(Enso.S("Invalid value for ", self.field$.owner().name(), ".", self.field$.name(), ":", self.field$.type().name(), " found ", mobj));
          }
          if (mobj.graph_identity() != self.owner$.graph_identity()) {
            return self.raise(Enso.S("Inserting object ", mobj, " into the wrong model"));
          }
        }
      }
    }; }};

class Ref extends Enso.mix(Single, RefHelpers) {
  static new(...args) { return new Ref(...args) };

  set(value) {
    var self = this;
    self.check(value);
    self.notify(self.get(), value);
    return self.__set(value);
  };

  __set(value) {
    var self = this;
    if (self.field$.traversal()) {
      if (value) {
        value.set___shell(self);
      }
      if (self.get() && ! value) {
        self.get().set___shell(null);
      }
    }
    return self.value$ = value;
  };

  _path(_) {
    var self = this;
    return self.owner$._path().field(self.field$.name());
  };

  __delete_obj(mobj) {
    var self = this;
    if (self.get() == mobj) {
      return self.set(null);
    }
  };
};

class Many extends Enso.mix(Field, RefHelpers, Enso.Enumerable) {
  static new(...args) { return new Many(...args) };

  get() {
    var self = this;
    return self;
  };

  set() {
    var self = this;
    return self.raise(Enso.S("Cannot assign to many-valued field ", self.field$.name()));
  };

  init(values) {
    var self = this;
    return values.each(function(value) {
      return self.push(value);
    });
  };

  __value() {
    var self = this;
    return self.value$;
  };

  get$(key) {
    var self = this;
    return self.__value().get$(key);
  };

  empty_P() {
    var self = this;
    return self.__value().empty_P();
  };

  size_M() {
    var self = this;
    return self.__value().size_M();
  };

  to_s() {
    var self = this;
    return self.__value().to_s();
  };

  connected_P() {
    var self = this;
    return self.owner$;
  };

  has_key_P(key) {
    var self = this;
    return self.keys().include_P(key);
  };

  check(mobj) {
    var self = this;
    if (self.connected_P()) {
      return super.check(mobj);
    }
  };

  notify(old, new_V) {
    var self = this;
    if (self.connected_P()) {
      return super.notify(old, new_V);
    }
  };

  __delete_obj(mobj) {
    var self = this;
    if (self.values().include_P(mobj)) {
      return self.delete_M(mobj);
    }
  };

  connect(mobj, shell) {
    var self = this;
    if (self.connected_P() && self.field$.traversal()) {
      return mobj.set___shell(shell);
    }
  };
};

class Set extends Enso.mix(Many, SetUtils) {
  static new(...args) { return new Set(...args) };

  constructor(owner, field, key) {
    super(owner, field);
    var self = this;
    self.value$ = Enso.EMap.new();
    self.key$ = key;
  };

  clear() {
    var self = this;
    return self.value$ = Enso.EMap.new();
  };

  each(block) {
    var self = this;
    return self.__value().each_value(block);
  };

  each_pair(block) {
    var self = this;
    return self.__value().each_pair(block);
  };

  find_first_pair(block) {
    var self = this;
    return self.__value().find_first_pair(block);
  };

  values() {
    var self = this;
    return self.__value().values();
  };

  keys() {
    var self = this;
    return self.__value().keys();
  };

  _recompute_hash_in_place() {
    var self = this, nval;
    nval = Enso.EMap.new();
    self.value$.each(function(k, v) {
      return nval .set$(v.get$(self.key$.name()), v);
    });
    self.value$ = nval;
    return self;
  };

  push(mobj) {
    var self = this, key;
    self.check(mobj);
    key = mobj.get$(self.key$.name());
    if (! key) {
      self.raise(Enso.S("Nil key when adding ", mobj, " to ", self));
    }
    if (self.value$.get$(key) != mobj) {
      if (self.value$.get$(key)) {
        self.delete_M(self.value$.get$(key));
      }
      self.notify(self.value$.get$(key), mobj);
      self.__insert(mobj);
    }
    return self;
  };

  set$(index, mobj) {
    var self = this;
    return self.push(mobj);
  };

  delete_M(mobj) {
    var self = this, key;
    key = mobj.get$(self.key$.name());
    if (self.value$.has_key_P(key)) {
      self.notify(self.value$.get$(key), null);
      return self.__delete(mobj);
    }
  };

  _path(mobj) {
    var self = this;
    return self.owner$._path().field(self.field$.name()).key(mobj.get$(self.key$.name()));
  };

  __insert(mobj) {
    var self = this;
    self.connect(mobj, self);
    return self.value$ .set$(mobj.get$(self.key$.name()), mobj);
  };

  __delete(mobj) {
    var self = this, deleted;
    deleted = self.value$.delete_M(mobj.get$(self.key$.name()));
    self.connect(deleted, null);
    return deleted;
  };
};

class List extends Enso.mix(Many, ListUtils) {
  static new(...args) { return new List(...args) };

  constructor(owner, field) {
    super(owner, field);
    var self = this;
    self.value$ = [];
  };

  clear() {
    var self = this;
    return self.value$ = [];
  };

  get$(key) {
    var self = this;
    return self.__value().get$(key.to_i());
  };

  each(block) {
    var self = this;
    return self.__value().each(block);
  };

  each_pair(block) {
    var self = this;
    return self.__value().each_with_index(function(item, i) {
      return block(i, item);
    });
  };

  values() {
    var self = this;
    return self.__value();
  };

  keys() {
    var self = this, x;
    x = [];
    Range.new(0, self.size() - 1).each(function(i) {
      return x.push(i);
    });
    return x;
  };

  push(mobj) {
    var self = this;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    self.check(mobj);
    self.notify(null, mobj);
    self.__insert(mobj);
    return self;
  };

  set$(index, mobj) {
    var self = this, old;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    old = self.__value().get$(index.to_i());
    if (old != mobj) {
      self.check(mobj);
      self.notify(null, mobj);
      self.__value() .set$(index.to_i(), mobj);
      if (old) {
        self.notify(old, null);
      }
    }
    return self;
  };

  delete_M(mobj) {
    var self = this, deleted;
    deleted = self.__delete(mobj);
    if (deleted) {
      self.notify(deleted, null);
    }
    return deleted;
  };

  insert(index, mobj) {
    var self = this;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    self.check(mobj);
    self.notify(null, mobj);
    self.value$.insert(index.to_i(), mobj);
    return self;
  };

  _path(mobj) {
    var self = this;
    return self.owner$._path().field(self.field$.name()).index(self.value$.index(mobj));
  };

  __insert(mobj) {
    var self = this;
    self.connect(mobj, self);
    return self.value$.push(mobj);
  };

  __delete(mobj) {
    var self = this, deleted;
    deleted = self.value$.delete_M(mobj);
    self.connect(deleted, null);
    return deleted;
  };
};

Factory = {
  make: make,
  SchemaFactory: SchemaFactory,
  IDCounterClass: IDCounterClass,
  IDCounter: IDCounter,
  MObject: MObject,
  Field: Field,
  Single: Single,
  Prim: Prim,
  SetUtils: SetUtils,
  ListUtils: ListUtils,
  RefHelpers: RefHelpers,
  Ref: Ref,
  Many: Many,
  Set: Set,
  List: List,
};
module.exports = Factory ;
