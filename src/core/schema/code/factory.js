require ( "core/schema/code/many" )
require ( "core/schema/code/dynamic" )
require ( "core/system/utils/paths" )
require ( "core/system/library/schema" )
require ( "core/semantics/code/interpreter" )
require ( "core/expr/code/impl" )
require ( "core/expr/code/env" )
require ( "core/expr/code/freevar" )

Factory = MakeClass( {
  schema: function() { return this.$.schema },

  initialize: function(schema) {
    var self = this; 
    var super$ = this.super$.initialize;
    self.$.schema = schema;
    self.$.roots = [];
    self.__constructor(schema.types());
    return self.$.file_path = [];
  },

  _get: function(name) {
    var self = this; 
    var super$ = this.super$._get;
    return self.send(name);
  },

  register: function(root) {
    var self = this; 
    var super$ = this.super$.register;
    return self.$.roots.push(root);
  },

  delete_in_place: function(obj) {
    var self = this; 
    var super$ = this.super$.delete_in_place;
    return self.$.roots.each(function(root) {
      return root.__delete_obj(obj);
    });
  },

  file_path: function() { return this.$.file_path },
  set_file_path: function(val) { this.$.file_path  = val },

  __constructor: function(klasses) {
    var self = this; 
    var super$ = this.super$.__constructor;
    return klasses.each(function(klass) {
      return self.define_singleton_method(function() {
        return MObject.new .call_rest_args$(MObject, klass, self, args );
      }, klass.name());
    });
  }
});

MObject = MakeClass( EnsoProxyObject, {
  _class_: {
    _id: 0
  },

  _origin: function() { return this.$._origin },
  set__origin: function(val) { this.$._origin  = val },

  __shell: function() { return this.$.__shell },
  set___shell: function(val) { this.$.__shell  = val },

  _id: function() { return this.$._id },

  factory: function() { return this.$.factory },

  schema_class: function() { return this.$.schema_class },

  extra_instance_data: function() { return this.$.extra_instance_data },
  set_extra_instance_data: function(val) { this.$.extra_instance_data  = val },

  initialize: function(klass, factory) {
    var self = this; 
    var args = compute_rest_arguments(arguments, 2 );
    var super$ = this.super$.initialize;
    self.$._id = self._class_._id = self._class_._id + 1;
    self.$.schema_class = klass;
    self.$.factory = factory;
    self.$.hash = new EnsoHash ( { } );
    self.$.listeners = new EnsoHash ( { } );
    self.$.memo = new EnsoHash ( { } );
    self.__setup(klass.all_fields());
    self.__init(klass.fields(), args);
    return self.__install(klass.all_fields());
  },

  _graph_id: function() {
    var self = this; 
    var super$ = this.super$._graph_id;
    return self.$.factory;
  },

  instance_of_P: function(sym) {
    var self = this; 
    var super$ = this.super$.instance_of_P;
    return self.schema_class().name() == sym.to_s();
  },

  _get: function(name) {
    var self = this; 
    var super$ = this.super$._get;
    if (name._get(- 1) == "?") {
      return self.schema_class().name() == name.slice(0, name.length() - 1);
    } else {
      self.check_field(name, true);
      if (self.computed_P(name)) {
        return self.send(name);
      } else {
        return self.__get(name).get();
      }
    }
  },

  _set: function(name, x) {
    var self = this; 
    var super$ = this.super$._set;
    self.check_field(name, false);
    return self.__get(name).set(x);
  },

  delete_in_place: function() {
    var self = this; 
    var super$ = this.super$.delete_in_place;
    return self.factory().delete_in_place(self);
  },

  __delete_obj: function(mobj) {
    var self = this; 
    var super$ = this.super$.__delete_obj;
    return self.schema_class().fields().each(function(fld) {
      if (fld.traversal()) {
        return self.__get(fld.name()).__delete_obj(mobj);
      }
    });
  },

  dynamic_update: function() {
    var self = this; 
    var super$ = this.super$.dynamic_update;
    return self.$.dyn = self.$.dyn || DynamicUpdateProxy.new(self);
  },

  add_listener: function(block, name) {
    var self = this; 
    var listeners;
    var super$ = this.super$.add_listener;
    listeners = self.$.listeners._get(name);
    if (! listeners) {
      listeners = self.$.listeners._get(name) = [];
    }
    return listeners.push(block);
  },

  notify: function(name, val) {
    var self = this; 
    var super$ = this.super$.notify;
    if (self.$.listeners._get(name)) {
      return self.$.listeners._get(name).each(function(blk) {
        return blk.call(val);
      });
    }
  },

  _origin_of: function(name) {
    var self = this; 
    var super$ = this.super$._origin_of;
    return self.__get(name)._origin();
  },

  _set_origin_of: function(name, org) {
    var self = this; 
    var super$ = this.super$._set_origin_of;
    return self.__get(name)._origin() = org;
  },

  _path_of: function(name) {
    var self = this; 
    var super$ = this.super$._path_of;
    return self._path().field(name);
  },

  _path: function() {
    var self = this; 
    var super$ = this.super$._path;
    if (self.__shell()) {
      return self.__shell()._path(self);
    } else {
      return Paths.new();
    }
  },

  _clone: function() {
    var self = this; 
    var r;
    var super$ = this.super$._clone;
    r = MObject.new(self.$.schema_class, self.$.factory);
    self.schema_class().fields().each(function(field) {
      if (field.many()) {
        return self._get(field.name()).each(function(o) {
          return r._get(field.name()).push(o);
        });
      } else {
        return r ._set( field.name() , self._get(field.name()) );
      }
    });
    return r;
  },

  __get: function(name) {
    var self = this; 
    var super$ = this.super$.__get;
    return self.$.hash._get(name);
  },

  __set: function(name, fld) {
    var self = this; 
    var super$ = this.super$.__set;
    return self.$.hash ._set( name , fld );
  },

  eql_P: function(o) {
    var self = this; 
    var super$ = this.super$.eql_P;
    return self == o;
  },

  equals: function(o) {
    var self = this; 
    var super$ = this.super$.equals;
    return (o && o.is_a_P(MObject)) && self._id() == o._id();
  },

  hash: function() {
    var self = this; 
    var super$ = this.super$.hash;
    return self._id();
  },

  to_s: function() {
    var self = this; 
    var k;
    var super$ = this.super$.to_s;
    k = Schema.class_key(self.schema_class());
    if (k) {
      return S("<<", self.schema_class().name(), " ", self._id(), " '", self._get(k.name()), "'>>");
    } else {
      return S("<<", self.schema_class().name(), " ", self._id(), ">>");
    }
  },

  finalize: function() {
    var self = this; 
    var super$ = this.super$.finalize;
    self.factory().register(self);
    return self;
  },

  check_field: function(name, can_be_computed) {
    var self = this; 
    var super$ = this.super$.check_field;
    if (! self.$.hash.include_P(name)) {
      self.raise(S("Non-existing field '", name, "' for ", self));
    }
    if (! can_be_computed && self.computed_P(name)) {
      return self.raise(S("Cannot assign to computed field '", name, "'"));
    }
  },

  computed_P: function(name) {
    var self = this; 
    var super$ = this.super$.computed_P;
    return self.__get(name) == "computed";
  },

  __setup: function(fields) {
    var self = this; 
    var klass, key, f;
    var super$ = this.super$.__setup;
    return fields.each(function(fld) {
      klass = self;
      f = fld.computed()
        ? "computed"
        : fld.type().Primitive_P()
          ? ManagedData.Prim().new(klass, fld)
          : ! fld.many()
            ? ManagedData.Ref().new(klass, fld)
            : key = Schema.class_key(fld.type())
              ? ManagedData.Set().new(klass, fld, key)
              : ManagedData.List().new(klass, fld)
      ;
      return self.__set(fld.name(), f);
    });
  },

  __init: function(fields, args) {
    var self = this; 
    var super$ = this.super$.__init;
    return fields.each_with_index(function(fld, i) {
      if (i < args.length()) {
        return self.__get(fld.name()).init(args._get(i));
      }
    });
  },

  __install: function(fields) {
    var self = this; 
    var c, base;
    var super$ = this.super$.__install;
    return fields.each(function(fld) {
      if (fld.computed()) {
        if (fld.computed().EList_P() && (c = fld.owner().supers().find(function(c) {
          return c.all_fields()._get(fld.name());
        }))) {
          base = c.all_fields()._get(fld.name());
          if (base.inverse()) {
            fld.computed().elems().each(function(var_V) {
              if (! var_V.EVar_P()) {
                self.raise(S("Field override ", fld.name(), " includes non-var ", var_V));
              }
              return self.__get(var_V.name())._set_inverse() = base.inverse();
            });
          }
        }
        return self.__computed(fld);
      } else {
        self.__setter(fld.name());
        return self.__getter(fld.name());
      }
    });
  },

  __computed: function(fld) {
    var self = this; 
    var name, exp, fvInterp, commInterp, fvs, val;
    var super$ = this.super$.__computed;
    name = fld.name();
    exp = fld.computed();
    fvInterp = Interpreter(FreeVarExpr);
    commInterp = Interpreter(EvalCommand);
    return self.define_singleton_method(function() {
      if (self.$.memo._get(name) == null) {
        fvs = fvInterp.depends(exp, new EnsoHash ( { } ));
        fvs.each(function(fv) {
          if (fv.object()) {
            return fv.object().add_listener(function() {
              return self.$.memo ._set( name , null );
            }, fv.index());
          }
        });
        val = commInterp.eval(exp, new EnsoHash ( { } ));
        self.$.memo ._set( name , val );
      }
      return self.$.memo._get(name);
    }, name);
  },

  __setter: function(name) {
    var self = this; 
    var super$ = this.super$.__setter;
  },

  __getter: function(name) {
    var self = this; 
    var super$ = this.super$.__getter;
  }
});

Field = MakeClass( {
  _origin: function() { return this.$._origin },
  set__origin: function(val) { this.$._origin  = val },

  set__set_inverse: function(inv) {
    var self = this; 
    var super$ = this.super$.set__set_inverse;
    if (self.$.inverse) {
      self.raise(S("Overiding inverse of field '", inv.owner().name(), ".", self.invk().name(), "'"));
    }
    return self.$.inverse = inv;
  },

  initialize: function(owner, field) {
    var self = this; 
    var super$ = this.super$.initialize;
    self.$.owner = owner;
    self.$.field = field;
    if (field) {
      return self.$.inverse = field.inverse();
    }
  },

  __delete_obj: function(mobj) {
    var self = this; 
    var super$ = this.super$.__delete_obj;
  },

  to_s: function() {
    var self = this; 
    var super$ = this.super$.to_s;
    return S(".", self.$.field.name(), " = ", self.$.value);
  }
});

Single = MakeClass( Field, {
  initialize: function(owner, field) {
    var self = this; 
    var super$ = this.super$.initialize;
    super$.call(self, owner, field);
    return self.$.value = self.default_V();
  },

  set: function(value) {
    var self = this; 
    var super$ = this.super$.set;
    self.check(value);
    self.$.value = value;
    return self.$.owner.notify(self.$.field.name(), value);
  },

  get: function() {
    var self = this; 
    var super$ = this.super$.get;
    return self.$.value;
  },

  init: function(value) {
    var self = this; 
    var super$ = this.super$.init;
    return self.set(value);
  },

  default: function() {
    var self = this; 
    var super$ = this.super$.default;
    return null;
  }
});

Prim = MakeClass( Single, {
  check: function(value) {
    var self = this; 
    var ok;
    var super$ = this.super$.check;
    if (! self.$.field.optional() || value) {
      ok = self.$.field.type().name() == "str"
        ? value.is_a_P(String)
        : self.$.field.type().name() == "int"
          ? value.is_a_P(Integer)
          : self.$.field.type().name() == "bool"
            ? value.is_a_P(TrueClass) || value.is_a_P(FalseClass)
            : self.$.field.type().name() == "real"
              ? value.is_a_P(Numeric)
              : self.$.field.type().name() == "datetime"
                ? value.is_a_P(DateTime)
                : ((function(){ {
                  if (self.$.field.type().name() == "atom") {
                    return ((value.is_a_P(Numeric) || value.is_a_P(String)) || value.is_a_P(TrueClass)) || value.is_a_P(FalseClass);
                  }
                } })())
      ;
      if (! ok) {
        return self.raise(S("Invalid value for ", self.$.field.type().name(), ": ", value));
      }
    }
  },

  default: function() {
    var self = this; 
    var super$ = this.super$.default;
    if (! self.$.field.optional()) {
      if (self.$.field.type().name() == "str") {
        return "";
      } else if (self.$.field.type().name() == "int") {
        return 0;
      } else if (self.$.field.type().name() == "bool") {
        return false;
      } else if (self.$.field.type().name() == "real") {
        return 0;
      } else if (self.$.field.type().name() == "datetime") {
        return DateTime.now();
      } else if (self.$.field.type().name() == "atom") {
        return null;
      } else {
        return self.raise(S("Unknown primitive type: ", self.$.field.type().name()));
      }
    }
  }
});

RefHelpers = MakeModule({
  notify: function(old, new_V) {
    var self = this; 
    var super$ = this.super$.notify;
    if (old != new_V) {
      self.$.owner.notify(self.$.field.name(), new_V);
      if (self.$.inverse) {
        if (self.$.inverse.many()) {
          if (old) {
            old.__get(self.$.inverse.name()).__delete(self.$.owner);
          }
          if (new_V) {
            return new_V.__get(self.$.inverse.name()).__insert(self.$.owner);
          }
        } else {
          if (old) {
            old.__get(self.$.inverse.name()).__set(null);
          }
          if (new_V) {
            return new_V.__get(self.$.inverse.name()).__set(self.$.owner);
          }
        }
      }
    }
  },

  check: function(mobj) {
    var self = this; 
    var super$ = this.super$.check;
    if (mobj || ! self.$.field.optional()) {
      if (mobj.nil_P()) {
        self.raise(S("Cannot assign nil to non-optional field ", self.$.field.name()));
      }
      if (! Schema.subclass_P(mobj.schema_class(), self.$.field.type())) {
        self.raise(S("Invalid value for '", self.$.field.owner().name(), ".", self.$.field.name(), "': ", mobj, " : ", mobj.schema_class().name()));
      }
      if (mobj._graph_id() != self.$.owner._graph_id()) {
        return self.raise(S("Inserting object ", mobj, " into the wrong model"));
      }
    }
  }
});

Ref = MakeClass( Single, {
  include: RefHelpers,

  set: function(value) {
    var self = this; 
    var super$ = this.super$.set;
    self.check(value);
    self.notify(self.get(), value);
    return self.__set(value);
  },

  __set: function(value) {
    var self = this; 
    var super$ = this.super$.__set;
    if (self.$.field.traversal()) {
      if (value) {
        value.__shell() = self;
      }
      if (self.get() && ! value) {
        self.get().__shell() = null;
      }
    }
    return self.$.value = value;
  },

  _path: function(_) {
    var self = this; 
    var super$ = this.super$._path;
    return self.$.owner._path().field(self.$.field.name());
  },

  __delete_obj: function(mobj) {
    var self = this; 
    var super$ = this.super$.__delete_obj;
    if (self.get() == mobj) {
      return self.set(null);
    }
  }
});

Many = MakeClass( Field, {
  include: RefHelpers,

  include: Enumerable,

  get: function() {
    var self = this; 
    var super$ = this.super$.get;
    return self;
  },

  set: function() {
    var self = this; 
    var super$ = this.super$.set;
    return self.raise(S("Cannot assign to many-valued field ", self.$.field.name()));
  },

  init: function(values) {
    var self = this; 
    var super$ = this.super$.init;
    return values.each(function(value) {
      return self.push(value);
    });
  },

  __value: function() {
    var self = this; 
    var super$ = this.super$.__value;
    return self.$.value;
  },

  _get: function(key) {
    var self = this; 
    var super$ = this.super$._get;
    return self.__value()._get(key);
  },

  empty_P: function() {
    var self = this; 
    var super$ = this.super$.empty_P;
    return self.__value().empty_P();
  },

  length: function() {
    var self = this; 
    var super$ = this.super$.length;
    return self.__value().length();
  },

  to_s: function() {
    var self = this; 
    var super$ = this.super$.to_s;
    return self.__value().to_s();
  },

  clear: function() {
    var self = this; 
    var super$ = this.super$.clear;
    return self.__value().clear();
  },

  connected_P: function() {
    var self = this; 
    var super$ = this.super$.connected_P;
    return self.$.owner;
  },

  has_key_P: function(key) {
    var self = this; 
    var super$ = this.super$.has_key_P;
    return self.keys().include_P(key);
  },

  check: function(mobj) {
    var self = this; 
    var super$ = this.super$.check;
    if (self.connected_P()) {
      return super$.call(self, mobj);
    }
  },

  notify: function(old, new_V) {
    var self = this; 
    var super$ = this.super$.notify;
    if (self.connected_P()) {
      return super$.call(self, old, new_V);
    }
  },

  __delete_obj: function(mobj) {
    var self = this; 
    var super$ = this.super$.__delete_obj;
    if (self.values().include_P(mobj)) {
      return self.delete(mobj);
    }
  },

  connect: function(mobj, shell) {
    var self = this; 
    var super$ = this.super$.connect;
    if (self.connected_P() && self.$.field.traversal()) {
      return mobj.__shell() = shell;
    }
  }
});

Set = MakeClass( Many, {
  include: SetUtils,

  initialize: function(owner, field, key) {
    var self = this; 
    var super$ = this.super$.initialize;
    super$.call(self, owner, field);
    self.$.value = new EnsoHash ( { } );
    return self.$.key = key;
  },

  each: function(block) {
    var self = this; 
    var super$ = this.super$.each;
    return self.__value().each_value();
  },

  each_pair: function(block) {
    var self = this; 
    var super$ = this.super$.each_pair;
    return self.__value().each_pair();
  },

  find_first_pair: function(block) {
    var self = this; 
    var super$ = this.super$.find_first_pair;
    return self.__value().find_first_pair();
  },

  values: function() {
    var self = this; 
    var super$ = this.super$.values;
    return self.__value().values();
  },

  keys: function() {
    var self = this; 
    var super$ = this.super$.keys;
    return self.__value().keys();
  },

  _recompute_hash_in_place: function() {
    var self = this; 
    var nval;
    var super$ = this.super$._recompute_hash_in_place;
    nval = new EnsoHash ( { } );
    self.$.value.each(function(k, v) {
      return nval ._set( v._get(self.$.key.name()) , v );
    });
    self.$.value = nval;
    return self;
  },

  push: function(mobj) {
    var self = this; 
    var key;
    var super$ = this.super$.push;
    self.check(mobj);
    key = mobj._get(self.$.key.name());
    if (! key) {
      self.raise(S("Nil key when adding ", mobj, " to ", self));
    }
    if (self.$.value._get(key) != mobj) {
      if (self.$.value._get(key)) {
        self.delete(self.$.value._get(key));
      }
      self.notify(self.$.value._get(key), mobj);
      self.__insert(mobj);
    }
    return self;
  },

  _set: function(index, mobj) {
    var self = this; 
    var super$ = this.super$._set;
    return self.push(mobj);
  },

  delete: function(mobj) {
    var self = this; 
    var key;
    var super$ = this.super$.delete;
    key = mobj._get(self.$.key.name());
    if (self.$.value.has_key_P(key)) {
      self.notify(self.$.value._get(key), null);
      return self.__delete(mobj);
    }
  },

  _path: function(mobj) {
    var self = this; 
    var super$ = this.super$._path;
    return self.$.owner._path().field(self.$.field.name()).key(mobj._get(self.$.key.name()));
  },

  __insert: function(mobj) {
    var self = this; 
    var super$ = this.super$.__insert;
    self.connect(mobj, self);
    return self.$.value ._set( mobj._get(self.$.key.name()) , mobj );
  },

  __delete: function(mobj) {
    var self = this; 
    var deleted;
    var super$ = this.super$.__delete;
    deleted = self.$.value.delete(mobj._get(self.$.key.name()));
    self.connect(deleted, null);
    return deleted;
  }
});

List = MakeClass( Many, {
  include: ListUtils,

  initialize: function(owner, field) {
    var self = this; 
    var super$ = this.super$.initialize;
    super$.call(self, owner, field);
    return self.$.value = [];
  },

  _get: function(key) {
    var self = this; 
    var super$ = this.super$._get;
    return self.__value()._get(key.to_i());
  },

  each: function(block) {
    var self = this; 
    var super$ = this.super$.each;
    return self.__value().each();
  },

  each_pair: function(block) {
    var self = this; 
    var super$ = this.super$.each_pair;
    return self.__value().each_with_index(function(item, i) {
      return block.call(i, item);
    });
  },

  values: function() {
    var self = this; 
    var super$ = this.super$.values;
    return self.__value();
  },

  keys: function() {
    var self = this; 
    var super$ = this.super$.keys;
    return Array.new(function(i) {
      return i;
    }, self.length());
  },

  push: function(mobj) {
    var self = this; 
    var super$ = this.super$.push;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    self.check(mobj);
    self.notify(null, mobj);
    self.__insert(mobj);
    return self;
  },

  _set: function(index, mobj) {
    var self = this; 
    var old;
    var super$ = this.super$._set;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    old = self.__value()._get(index.to_i());
    if (old != mobj) {
      self.check(mobj);
      self.notify(null, mobj);
      self.__value() ._set( index.to_i() , mobj );
      if (old) {
        self.notify(old, null);
      }
    }
    return self;
  },

  delete: function(mobj) {
    var self = this; 
    var deleted;
    var super$ = this.super$.delete;
    deleted = self.__delete(mobj);
    if (deleted) {
      self.notify(deleted, null);
    }
    return deleted;
  },

  insert: function(index, mobj) {
    var self = this; 
    var super$ = this.super$.insert;
    if (! mobj) {
      self.raise("Cannot insert nil into list");
    }
    self.check(mobj);
    self.notify(null, mobj);
    self.$.value.insert(index.to_i(), mobj);
    return self;
  },

  _path: function(mobj) {
    var self = this; 
    var super$ = this.super$._path;
    return self.$.owner._path().field(self.$.field.name()).index(self.$.value.index(mobj));
  },

  __insert: function(mobj) {
    var self = this; 
    var super$ = this.super$.__insert;
    self.connect(mobj, self);
    return self.$.value.push(mobj);
  },

  __delete: function(mobj) {
    var self = this; 
    var deleted;
    var super$ = this.super$.__delete;
    deleted = self.$.value.delete(mobj);
    self.connect(deleted, null);
    return deleted;
  }
});

exports = ManagedData = {
  Factory: Factory,
  MObject: MObject,
  Field: Field,
  Single: Single,
  Prim: Prim,
  RefHelpers: RefHelpers,
  Ref: Ref,
  Many: Many,
  Set: Set,
  List: List,

  new: function(schema) {
    return Factory.new(schema);
  }
}
