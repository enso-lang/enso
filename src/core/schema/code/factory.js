require ( "enso" )
require ( "core/schema/code/many" )
require ( "core/schema/code/dynamic" )
require ( "core/system/utils/paths" )
require ( "core/system/library/schema" )
require ( "core/semantics/code/interpreter" )
require ( "core/expr/code/impl" )
require ( "core/expr/code/env" )
require ( "core/expr/code/freevar" )
Factory = MakeClass( {
  schema: function ( ) { return this.$.schema },

  initialize: function( schema ) {
    var self=this;
    self.$.schema = schema;
    self.$.roots = [];
    __constructor(schema.types());
    self.$.file_path = [];
  },

  _get: function( name ) {
    var self=this;
    return send(name);
  },

  register: function( root ) {
    var self=this;
    return self.$.roots.push(root);
  },

  delete_in_place: function( obj ) {
    var self=this;
    return self.$.roots.each(function(root) {
      return root.__delete_obj(obj);
    });
  },

  file_path: function ( ) { return this.$.file_path },
  set_file_path: function (val) { this.$.file_path =val },

  __constructor: function( klasses ) {
    var self=this;
    return klasses.each(function(klass) {
      return define_singleton_method(function() {
        return MObject.new(klass, self);
      }, klass.name());
    });
  }
});

MObject = MakeClass( {
  _class_: {
    _id: 0
  },

  _origin: function ( ) { return this.$._origin },
  set__origin: function (val) { this.$._origin =val },

  __shell: function ( ) { return this.$.__shell },
  set___shell: function (val) { this.$.__shell =val },

  _id: function ( ) { return this.$._id },

  factory: function ( ) { return this.$.factory },

  schema_class: function ( ) { return this.$.schema_class },

  initialize: function( klass, factory ) {
    var self=this;
    var args = compute_rest_arguments(arguments, 2 );
    self.$._id = self._class_._id += 1;
    self.$.schema_class = klass;
    self.$.factory = factory;
    self.$.hash = new EnsoHash ( { } );
    self.$.listeners = new EnsoHash ( { } );
    self.$.memo = new EnsoHash ( { } );
    __setup(klass.all_fields());
    __init(klass.fields(), args);
    __install(klass.all_fields());
  },

  method_missing: function( block, sym ) {
    var self=this;
    var args = compute_rest_arguments(arguments, 2 );
    if (sym._get(- 1) == "?") {
      return schema_class.name() == sym.slice(0, sym.length() - 1);
    } else {
      return this.super$.  .call(self,  sym );
    }
  },

  _graph_id: function( ) {
    var self=this;
    return self.$.factory;
  },

  instance_of_p: function( sym ) {
    var self=this;
    return schema_class.name() == sym.to_s();
  },

  _get: function( name ) {
    var self=this;
    check_field(name, true);
    if (computed_p(name)) {
      return send(name);
    } else {
      return __get(name).get();
    }
  },

  _set: function( name, x ) {
    var self=this;
    check_field(name, false);
    return __get(name).set(x);
  },

  delete_in_place: function( ) {
    var self=this;
    return factory.delete_in_place(self);
  },

  __delete_obj: function( mobj ) {
    var self=this;
    return schema_class.fields().each(function(fld) {
      if (fld.traversal()) {
        return __get(fld.name()).__delete_obj(mobj);
      }
    });
  },

  dynamic_update: function( ) {
    var self=this;
    return self.$.dyn ||= DynamicUpdateProxy.new(self);
  },

  add_listener: function( block, name ) {
    var self=this;
    return (self.$.listeners ._set( name , [] )).push(block);
  },

  notify: function( name, val ) {
    var self=this;
    if (self.$.listeners._get(name)) {
      return self.$.listeners._get(name).each(function(blk) {
        return blk.call(val);
      });
    }
  },

  _origin_of: function( name ) {
    var self=this;
    return __get(name)._origin();
  },

  _set_origin_of: function( name, org ) {
    var self=this;
    return __get(name)._origin() = org;
  },

  _path_of: function( name ) {
    var self=this;
    return _path.field(name);
  },

  _path: function( ) {
    var self=this;
    if (__shell) {
      return __shell._path(self);
    } else {
      return Paths.new();
    }
  },

  _clone: function( ) {
    var self=this;
    r = MObject.new(self.$.schema_class, self.$.factory);
    schema_class.fields().each(function(field) {
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

  __get: function( name ) {
    var self=this;
    return self.$.hash._get(name);
  },

  __set: function( name, fld ) {
    var self=this;
    return self.$.hash ._set( name , fld );
  },

  eql_p: function( o ) {
    var self=this;
    return self == o;
  },

  equals: function( o ) {
    var self=this;
    return (o && o.is_a_p(MObject)) && _id == o._id();
  },

  hash: function( ) {
    var self=this;
    return _id;
  },

  to_s: function( ) {
    var self=this;
    k = ClassKey(schema_class);
    if (k) {
      return str("<<", schema_class.name(), " ", _id, " '", self._get(k.name()), "'>>");
    } else {
      return str("<<", schema_class.name(), " ", _id, ">>");
    }
  },

  finalize: function( ) {
    var self=this;
    factory.register(self);
    return self;
  },

  check_field: function( name, can_be_computed ) {
    var self=this;
    if (! self.$.hash.include_p(name)) {
      raise(str("Non-existing field '", name, "' for ", self));
    }
    if (! can_be_computed && computed_p(name)) {
      return raise(str("Cannot assign to computed field '", name, "'"));
    }
  },

  computed_p: function( name ) {
    var self=this;
    return __get(name) == "computed";
  },

  __setup: function( fields ) {
    var self=this;
    return fields.each(function(fld) {
      klass = self;
      f = fld.computed()
        ? "computed"
        : fld.type().Primitive_p()
          ? ManagedData.Prim().new(klass, fld)
          : ! fld.many()
            ? ManagedData.Ref().new(klass, fld)
            : key = ClassKey(fld.type())
              ? ManagedData.Set().new(klass, fld, key)
              : ManagedData.List().new(klass, fld)
      ;
      return __set(fld.name(), f);
    });
  },

  __init: function( fields, args ) {
    var self=this;
    return fields.each_with_index(function(fld, i) {
      if (i < args.length()) {
        return __get(fld.name()).init(args._get(i));
      }
    });
  },

  __install: function( fields ) {
    var self=this;
    return fields.each(function(fld) {
      if (fld.computed()) {
        if (fld.computed().EList_p() && (c = fld.owner().supers().find(function(c) {
          return c.all_fields()._get(fld.name());
        }))) {
          base = c.all_fields()._get(fld.name());
          if (base.inverse()) {
            fld.computed().elems().each(function(var) {
              if (! var.EVar_p()) {
                raise(str("Field override ", fld.name(), " includes non-var ", var));
              }
              return __get(var.name())._set_inverse() = base.inverse();
            });
          }
        }
        return __computed(fld);
      } else {
        __setter(fld.name());
        return __getter(fld.name());
      }
    });
  },

  __computed: function( fld ) {
    var self=this;
    name = fld.name();
    exp = fld.computed();
    fvInterp = Interpreter(FreeVarExpr);
    commInterp = Interpreter(EvalCommand);
    return define_singleton_method(function() {
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

  __setter: function( name ) {
    var self=this;
    return define_singleton_method(function(arg) {
      return self ._set( name , arg );
    }, str(name, "="));
  },

  __getter: function( name ) {
    var self=this;
    return define_singleton_method(function() {
      return self._get(name);
    }, name);
  }
});

Field = MakeClass( {
  _origin: function ( ) { return this.$._origin },
  set__origin: function (val) { this.$._origin =val },

  set__set_inverse: function( inv ) {
    var self=this;
    if (self.$.inverse) {
      raise(str("Overiding inverse of field '", inv.owner().name(), ".", invk.name(), "'"));
    }
    return self.$.inverse = inv;
  },

  initialize: function( owner, field ) {
    var self=this;
    self.$.owner = owner;
    self.$.field = field;
    if (field) {
      self.$.inverse = field.inverse();
    }
  },

  __delete_obj: function( mobj ) {
    var self=this;
  },

  to_s: function( ) {
    var self=this;
    return str(".", self.$.field.name(), " = ", self.$.value);
  }
});

Single = MakeClass( Field, {
  initialize: function( owner, field ) {
    var self=this;
    this.super$.  .call(self,  owner, field );
    self.$.value = default;
  },

  set: function( value ) {
    var self=this;
    check(value);
    self.$.value = value;
    return self.$.owner.notify(self.$.field.name(), value);
  },

  get: function( ) {
    var self=this;
    return self.$.value;
  },

  init: function( value ) {
    var self=this;
    return set(value);
  },

  default: function( ) {
    var self=this;
    return null;
  }
});

Prim = MakeClass( Single, {
  check: function( value ) {
    var self=this;
    if (! self.$.field.optional() || value) {
      ok = self.$.field.type().name() == "str"
        ? value.is_a_p(String)
        : self.$.field.type().name() == "int"
          ? value.is_a_p(Integer)
          : self.$.field.type().name() == "bool"
            ? value.is_a_p(TrueClass) || value.is_a_p(FalseClass)
            : self.$.field.type().name() == "real"
              ? value.is_a_p(Numeric)
              : self.$.field.type().name() == "datetime"
                ? value.is_a_p(DateTime)
                : ((function(){ {
                  if (self.$.field.type().name() == "atom") {
                    return ((value.is_a_p(Numeric) || value.is_a_p(String)) || value.is_a_p(TrueClass)) || value.is_a_p(FalseClass);
                  }
                } })())
      ;
      if (! ok) {
        return raise(str("Invalid value for ", self.$.field.type().name(), ": ", value));
      }
    }
  },

  default: function( ) {
    var self=this;
    if (! self.$.field.optional()) {
      if (self.$.field.type().name() == "str") {
        return "";
      } else if (self.$.field.type().name() == "int") {
        return 0;
      } else if (self.$.field.type().name() == "bool") {
        return false;
      } else if (self.$.field.type().name() == "real") {
        return 0.0;
      } else if (self.$.field.type().name() == "datetime") {
        return DateTime.now();
      } else if (self.$.field.type().name() == "atom") {
        return null;
      } else {
        return raise(str("Unknown primitive type: ", self.$.field.type().name()));
      }
    }
  }
});

RefHelpers = MakeModule({
  notify: function( old, new ) {
    var self=this;
    if (old != new) {
      self.$.owner.notify(self.$.field.name(), new);
      if (self.$.inverse) {
        if (self.$.inverse.many()) {
          if (old) {
            old.__get(self.$.inverse.name()).__delete(self.$.owner);
          }
          if (new) {
            return new.__get(self.$.inverse.name()).__insert(self.$.owner);
          }
        } else {
          if (old) {
            old.__get(self.$.inverse.name()).__set(null);
          }
          if (new) {
            return new.__get(self.$.inverse.name()).__set(self.$.owner);
          }
        }
      }
    }
  },

  check: function( mobj ) {
    var self=this;
    if (mobj || ! self.$.field.optional()) {
      if (mobj.nil_p()) {
        raise(str("Cannot assign nil to non-optional field ", self.$.field.name()));
      }
      if (! Subclass_p(mobj.schema_class(), self.$.field.type())) {
        raise(str("Invalid value for '", self.$.field.owner().name(), ".", self.$.field.name(), "': ", mobj, " : ", mobj.schema_class().name()));
      }
      if (mobj._graph_id() != self.$.owner._graph_id()) {
        return raise(str("Inserting object ", mobj, " into the wrong model"));
      }
    }
  }
});

Ref = MakeClass( Single, {
  include: RefHelpers,

  set: function( value ) {
    var self=this;
    check(value);
    notify(get, value);
    return __set(value);
  },

  __set: function( value ) {
    var self=this;
    if (self.$.field.traversal()) {
      if (value) {
        value.__shell() = self;
      }
      if (get && ! value) {
        get.__shell() = null;
      }
    }
    return self.$.value = value;
  },

  _path: function( _ ) {
    var self=this;
    return self.$.owner._path().field(self.$.field.name());
  },

  __delete_obj: function( mobj ) {
    var self=this;
    if (get == mobj) {
      return set(null);
    }
  }
});

Many = MakeClass( Field, {
  include: RefHelpers,

  include: Enumerable,

  get: function( ) {
    var self=this;
    return self;
  },

  set: function( ) {
    var self=this;
    return raise(str("Cannot assign to many-valued field ", self.$.field.name()));
  },

  init: function( values ) {
    var self=this;
    return values.each(function(value) {
      return self.push(value);
    });
  },

  __value: function( ) {
    var self=this;
    return self.$.value;
  },

  _get: function( key ) {
    var self=this;
    return __value._get(key);
  },

  empty_p: function( ) {
    var self=this;
    return __value.empty_p();
  },

  length: function( ) {
    var self=this;
    return __value.length();
  },

  to_s: function( ) {
    var self=this;
    return __value.to_s();
  },

  clear: function( ) {
    var self=this;
    return __value.clear();
  },

  connected_p: function( ) {
    var self=this;
    return self.$.owner;
  },

  has_key_p: function( key ) {
    var self=this;
    return keys.include_p(key);
  },

  check: function( mobj ) {
    var self=this;
    if (connected_p) {
      return this.super$.  .call(self,  mobj );
    }
  },

  notify: function( old, new ) {
    var self=this;
    if (connected_p) {
      return this.super$.  .call(self,  old, new );
    }
  },

  __delete_obj: function( mobj ) {
    var self=this;
    if (values.include_p(mobj)) {
      return delete(mobj);
    }
  },

  connect: function( mobj, shell ) {
    var self=this;
    if (connected_p && self.$.field.traversal()) {
      return mobj.__shell() = shell;
    }
  }
});

Set = MakeClass( Many, {
  include: SetUtils,

  initialize: function( owner, field, key ) {
    var self=this;
    this.super$.  .call(self,  owner, field );
    self.$.value = new EnsoHash ( { } );
    self.$.key = key;
  },

  each: function( block ) {
    var self=this;
    return __value.each_value();
  },

  each_pair: function( block ) {
    var self=this;
    return __value.each_pair();
  },

  values: function( ) {
    var self=this;
    return __value.values();
  },

  keys: function( ) {
    var self=this;
    return __value.keys();
  },

  _recompute_hash_in_place: function( ) {
    var self=this;
    nval = new EnsoHash ( { } );
    self.$.value.each(function(k, v) {
      return nval ._set( v._get(self.$.key.name()) , v );
    });
    self.$.value = nval;
    return self;
  },

  push: function( mobj ) {
    var self=this;
    check(mobj);
    key = mobj._get(self.$.key.name());
    if (! key) {
      raise(str("Nil key when adding ", mobj, " to ", self));
    }
    if (self.$.value._get(key) != mobj) {
      if (self.$.value._get(key)) {
        delete(self.$.value._get(key));
      }
      notify(self.$.value._get(key), mobj);
      __insert(mobj);
    }
    return self;
  },

  _set: function( index, mobj ) {
    var self=this;
    return self.push(mobj);
  },

  delete: function( mobj ) {
    var self=this;
    key = mobj._get(self.$.key.name());
    if (self.$.value.has_key_p(key)) {
      notify(self.$.value._get(key), null);
      return __delete(mobj);
    }
  },

  _path: function( mobj ) {
    var self=this;
    return self.$.owner._path().field(self.$.field.name()).key(mobj._get(self.$.key.name()));
  },

  __insert: function( mobj ) {
    var self=this;
    connect(mobj, self);
    return self.$.value ._set( mobj._get(self.$.key.name()) , mobj );
  },

  __delete: function( mobj ) {
    var self=this;
    deleted = self.$.value.delete(mobj._get(self.$.key.name()));
    connect(deleted, null);
    return deleted;
  }
});

List = MakeClass( Many, {
  include: ListUtils,

  initialize: function( owner, field ) {
    var self=this;
    this.super$.  .call(self,  owner, field );
    self.$.value = [];
  },

  _get: function( key ) {
    var self=this;
    return __value._get(key.to_i());
  },

  each: function( block ) {
    var self=this;
    return __value.each();
  },

  each_pair: function( block ) {
    var self=this;
    return __value.each_with_index(function(item, i) {
      return block.call(i, item);
    });
  },

  values: function( ) {
    var self=this;
    return __value;
  },

  keys: function( ) {
    var self=this;
    return Array.new(function(i) {
      return i;
    }, length);
  },

  push: function( mobj ) {
    var self=this;
    if (! mobj) {
      raise("Cannot insert nil into list");
    }
    check(mobj);
    notify(null, mobj);
    __insert(mobj);
    return self;
  },

  _set: function( index, mobj ) {
    var self=this;
    if (! mobj) {
      raise("Cannot insert nil into list");
    }
    check(mobj);
    notify(null, mobj);
    old = __value._get(index.to_i());
    __value ._set( index.to_i() , mobj );
    if (old) {
      notify(old, null);
    }
    return self;
  },

  delete: function( mobj ) {
    var self=this;
    deleted = __delete(mobj);
    if (deleted) {
      notify(deleted, null);
    }
    return deleted;
  },

  insert: function( index, mobj ) {
    var self=this;
    if (! mobj) {
      raise("Cannot insert nil into list");
    }
    check(mobj);
    notify(null, mobj);
    self.$.value.insert(index.to_i(), mobj);
    return self;
  },

  _path: function( mobj ) {
    var self=this;
    return self.$.owner._path().field(self.$.field.name()).index(self.$.value.index(mobj));
  },

  __insert: function( mobj ) {
    var self=this;
    connect(mobj, self);
    return self.$.value.push(mobj);
  },

  __delete: function( mobj ) {
    var self=this;
    deleted = self.$.value.delete(mobj);
    connect(deleted, null);
    return deleted;
  }
});

new = function(schema) {
  return Factory.new(schema);
}
