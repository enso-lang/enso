define([
  "core/schema/code/dynamic",
  "core/system/utils/paths",
  "core/system/library/schema",
  "core/semantics/code/interpreter",
  "core/expr/code/impl",
  "core/expr/code/env",
  "core/expr/code/freevar"
],
function(Dynamic, Paths, Schema, Interpreter, Impl, Env, Freevar) {

  var Factory ;

  var SchemaFactory = MakeClass(null, [],
    function() {
    },
    function(super$) {
      this.schema = function() { return this.$.schema };

      this.file_path = function() { return this.$.file_path };
      this.set_file_path = function(val) { this.$.file_path  = val };

      this.initialize = function(schema) {
        var self = this; 
        self.$.schema = schema;
        self.$.roots = [];
        self.$.file_path = [];
        return schema.classes().each(function(klass) {
          return self.define_singleton_method(function() {
            var args = compute_rest_arguments(arguments, 0 );
            return MObject.new.apply(MObject, [klass, self].concat( args ));
          }, klass.name());
        });
      };

      this._get = function(name) {
        var self = this; 
        return self.send(name);
      };

      this.register = function(root) {
        var self = this; 
        if (self.$.root) {
          self.raise("Creating two roots");
        }
        return self.$.root = root;
      };
    });

  var MObject = MakeClass(EnsoProxyObject, [],
    function() {
      this.$._id = 0;
    },
    function(super$) {
      this._origin = function() { return this.$._origin };
      this.set__origin = function(val) { this.$._origin  = val };

      this.__shell = function() { return this.$.__shell };
      this.set___shell = function(val) { this.$.__shell  = val };

      this._id = function() { return this.$._id };

      this.factory = function() { return this.$.factory };

      this.extra_instance_data = function() { return this.$.extra_instance_data };
      this.set_extra_instance_data = function(val) { this.$.extra_instance_data  = val };

      this.initialize = function(klass, factory) {
        var self = this; 
        var args = compute_rest_arguments(arguments, 2 );
        self.$._id = self._class_.$._id = self._class_.$._id + 1;
        self.$.listeners = new EnsoHash ( { } );
        self.$.props = new EnsoHash ( { } );
        self.define_singleton_value("schema_class", klass);
        self.$.factory = factory;
        self.__is_a(klass);
        self.__to_s(klass);
        klass.all_fields().each(function(fld) {
          return self.__setup(fld);
        });
        return klass.fields().each_with_index(function(fld, i) {
          if (i < args.length) {
            if (fld.many()) {
              return args._get(i).each(function(value) {
                return self._get(fld.name()).push(value);
              });
            } else {
              return self._set(fld.name(), args._get(i));
            }
          }
        });
      };

      this.__setup = function(fld) {
        var self = this; 
        var prop, key, collection;
        if (fld.computed()) {
          return self.__computed(fld);
        } else if (! fld.many()) {
          if (fld.type().Primitive_P()) {
            prop = Prim.new(self, fld);
          } else {
            prop = Ref.new(self, fld);
          }
          self.$.props._set(fld.name(), prop);
          self.define_getter(fld.name(), prop);
          return self.define_setter(fld.name(), prop);
        } else {
          if (key = Schema.class_key(fld.type())) {
            collection = Set.new(self, fld, key);
          } else {
            collection = List.new(self, fld);
          }
          self.$.props._set(fld.name(), collection);
          return self.define_singleton_value(fld.name(), collection);
        }
      };

      this.__get = function(name) {
        var self = this; 
        return self.$.props._get(name);
      };

      this.__is_a = function(klass) {
        var self = this; 
        var val;
        return klass.schema().classes().each(function(cls) {
          val = Schema.subclass_P(klass, cls);
          return self.define_singleton_value(S(cls.name(), "?"), val);
        });
      };

      this.__to_s = function(cls) {
        var self = this; 
        var k;
        k = Schema.class_key(cls);
        if (k) {
          return self.define_singleton_method(function() {
            return S("<<", cls.name(), " ", self._id(), " '", self._get(k.name()), "'>>");
          }, "to_s");
        } else {
          return self.define_singleton_value("to_s", S("<<", cls.name(), " ", self._id(), ">>"));
        }
      };

      this.__computed = function(fld) {
        var self = this; 
        var c, base, name, exp, fvInterp, commInterp, val, fvs, var_V;
        if (fld.computed().EList_P() && (c = fld.owner().supers().find(function(c) {
          return c.all_fields()._get(fld.name());
        }))) {
          base = c.all_fields()._get(fld.name());
          if (base.inverse()) {
            fld.computed().elems().each(function(var_V) {
              if (! var_V.EVar_P()) {
                self.raise(S("Field override ", fld.name(), " includes non-var ", var_V));
              }
              return self.__get(var_V.name())._set_inverse = base.inverse();
            });
          }
        }
        name = fld.name();
        exp = fld.computed();
        fvInterp = Freevar.FreeVarExprC.new();
        commInterp = Impl.EvalCommandC.new();
        val = null;
        return self.define_singleton_method(function() {
          if (val == null) {
            fvs = fvInterp.dynamic_bind(function() {
              return fvInterp.depends(exp);
            }, new EnsoHash ( { env: Env.ObjEnv.new(self), bound: [] } ));
            fvs.each(function(fv) {
              if (fv.object()) {
                return fv.object().add_listener(function() {
                  return var_V = null;
                }, fv.index());
              }
            });
            val = commInterp.dynamic_bind(function() {
              return commInterp.eval(exp);
            }, new EnsoHash ( { env: Env.ObjEnv.new(self), for_field: fld } ));
            var_V = val;
          }
          return val;
        }, name);
      };

      this._graph_id = function() {
        var self = this; 
        return self.$.factory;
      };

      this.instance_of_P = function(sym) {
        var self = this; 
        return self.schema_class().name() == sym.to_s();
      };

      this.delete_in_place = function() {
        var self = this; 
        return self.factory().delete_in_place(self);
      };

      this.__delete_obj = function(mobj) {
        var self = this; 
        return self.schema_class().fields().each(function(fld) {
          if (fld.traversal()) {
            return self.__get(fld.name()).__delete_obj(mobj);
          }
        });
      };

      this.dynamic_update = function() {
        var self = this; 
        return self.$.dyn = self.$.dyn || DynamicUpdateProxy.new(self);
      };

      this.add_listener = function(block, name) {
        var self = this; 
        var listeners;
        listeners = self.$.listeners._get(name);
        if (! listeners) {
          listeners = self.$.listeners._get(name) = [];
        }
        return listeners.push(block);
      };

      this.notify = function(name, val) {
        var self = this; 
        if (self.$.listeners._get(name)) {
          return self.$.listeners._get(name).each(function(blk) {
            return blk(val);
          });
        }
      };

      this._origin_of = function(name) {
        var self = this; 
        return self.__get(name)._origin();
      };

      this._set_origin_of = function(name, org) {
        var self = this; 
        return self.__get(name)._origin = org;
      };

      this._path_of = function(name) {
        var self = this; 
        return self._path().field(name);
      };

      this._path = function() {
        var self = this; 
        if (self.__shell()) {
          return self.__shell()._path(self);
        } else {
          return Paths.new();
        }
      };

      this._clone = function() {
        var self = this; 
        var r;
        r = MObject.new(self.schema_class(), self.$.factory);
        self.schema_class().fields().each(function(field) {
          if (field.many()) {
            return self._get(field.name()).each(function(o) {
              return r._get(field.name()).push(o);
            });
          } else {
            return r._set(field.name(), self._get(field.name()));
          }
        });
        return r;
      };

      this.eql_P = function(o) {
        var self = this; 
        return self == o;
      };

      this.equals = function(o) {
        var self = this; 
        return (o && System.test_type(o, MObject)) && self._id() == o._id();
      };

      this.hash = function() {
        var self = this; 
        return self.$._id;
      };

      this.finalize = function() {
        var self = this; 
        self.factory().register(self);
        return self;
      };
    });

  var Field = MakeClass(null, [],
    function() {
    },
    function(super$) {
      this._origin = function() { return this.$._origin };
      this.set__origin = function(val) { this.$._origin  = val };

      this.initialize = function(owner, field) {
        var self = this; 
        self.$.owner = owner;
        self.$.field = field;
        if (field) {
          return self.$.inverse = field.inverse();
        }
      };

      this.set__set_inverse = function(inv) {
        var self = this; 
        if (self.$.inverse) {
          self.raise(S("Overiding inverse of field '", inv.owner().name(), ".", self.invk().name(), "'"));
        }
        return self.$.inverse = inv;
      };

      this.__delete_obj = function(mobj) {
        var self = this; 
      };

      this.to_s = function() {
        var self = this; 
        return S(".", self.$.field.name(), " = ", self.$.value);
      };
    });

  var Single = MakeClass(Field, [],
    function() {
    },
    function(super$) {
      this.initialize = function(owner, field) {
        var self = this; 
        super$.initialize.call(self, owner, field);
        return self.$.value = self.default();
      };

      this.set = function(value) {
        var self = this; 
        self.check(value);
        self.$.value = value;
        return self.$.owner.notify(self.$.field.name(), value);
      };

      this.get = function() {
        var self = this; 
        return self.$.value;
      };

      this.init = function(value) {
        var self = this; 
        return self.set(value);
      };

      this.default = function() {
        var self = this; 
        return null;
      };
    });

  var Prim = MakeClass(Single, [],
    function() {
    },
    function(super$) {
      this.check = function(value) {
        var self = this; 
        var ok;
        if (! self.$.field.optional() || value) {
          ok = self.$.field.type().name() == "str"
            ? System.test_type(value, String)
            : self.$.field.type().name() == "int"
              ? System.test_type(value, Integer)
              : self.$.field.type().name() == "bool"
                ? System.test_type(value, TrueClass) || System.test_type(value, FalseClass)
                : self.$.field.type().name() == "real"
                  ? System.test_type(value, Numeric)
                  : self.$.field.type().name() == "datetime"
                    ? System.test_type(value, DateTime)
                    : ((function(){ {
                      if (self.$.field.type().name() == "atom") {
                        return ((System.test_type(value, Numeric) || System.test_type(value, String)) || System.test_type(value, TrueClass)) || System.test_type(value, FalseClass);
                      }
                    } })())
          ;
          if (! ok) {
            return self.raise(S("Invalid value for ", self.$.field.name(), ":", self.$.field.type().name(), " = ", value));
          }
        }
      };

      this.default = function() {
        var self = this; 
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
            return self.raise(S("Unknown primitive type: ", self.$.field.type().name()));
          }
        }
      };
    });

  var SetUtils = MakeMixin([], function() {
    this.to_ary = function() {
      var self = this; 
      return self.$.values.values();
    };

    this.add = function(other) {
      var self = this; 
      var r;
      r = self.inject(function(x) {
        return x.push();
      }, Set.new(null, self.$.field, self.__key() || other.__key()));
      return other.inject(function(x) {
        return x.push();
      }, r);
    };

    this.select = function(block) {
      var self = this; 
      var result;
      result = Set.new(null, self.$.field, self.__key());
      self.each(function(elt) {
        if (block(elt)) {
          return result.push(elt);
        }
      });
      return result;
    };

    this.flat_map = function(block) {
      var self = this; 
      var new_V, set, key;
      new_V = null;
      self.each(function(x) {
        set = block(x);
        if (new_V == null) {
          key = set.__key();
          new_V = Set.new(null, self.$.field, key);
        } else {
        }
        return set.each(function(y) {
          return new_V.push(y);
        });
      });
      return new_V || Set.new(null, self.$.field, self.__key());
    };

    this.each_with_match = function(block, other) {
      var self = this; 
      var empty;
      empty = Set.new(null, self.$.field, self.__key());
      return self.__outer_join(function(sa, sb) {
        if ((sa && sb) && sa._get(self.__key().name()) == sb._get(self.__key().name())) {
          return block(sa, sb);
        } else if (sa) {
          return block(sa, null);
        } else if (sb) {
          return block(null, sb);
        }
      }, other || empty);
    };

    this.__key = function() {
      var self = this; 
      return self.$.key;
    };

    this.__keys = function() {
      var self = this; 
      return self.$.value.keys();
    };

    this.__outer_join = function(block, other) {
      var self = this; 
      var keys;
      keys = self.__keys().union(other.__keys());
      return keys.each(function(key) {
        return block(self._get(key), other._get(key), key);
      });
    };
  });

  var ListUtils = MakeMixin([], function() {
    this.each_with_match = function(block, other) {
      var self = this; 
      if (! self.empty_P()) {
        return self.each(function(item) {
          return block(item, null);
        });
      }
    };
  });

  var RefHelpers = MakeMixin([], function() {
    this.notify = function(old, new_V) {
      var self = this; 
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
    };

    this.check = function(mobj) {
      var self = this; 
      if (mobj || ! self.$.field.optional()) {
        if (mobj == null) {
          self.raise(S("Cannot assign nil to non-optional field ", self.$.field.name()));
        }
        if (! Schema.subclass_P(mobj.schema_class(), self.$.field.type())) {
          self.raise(S("Invalid value for '", self.$.field.owner().name(), ".", self.$.field.name(), "': ", mobj, " : ", mobj.schema_class().name()));
        }
        if (mobj._graph_id() != self.$.owner._graph_id()) {
          return self.raise(S("Inserting object ", mobj, " into the wrong model"));
        }
      }
    };
  });

  var Ref = MakeClass(Single, [RefHelpers],
    function() {
    },
    function(super$) {
      this.set = function(value) {
        var self = this; 
        self.check(value);
        self.notify(self.get(), value);
        return self.__set(value);
      };

      this.__set = function(value) {
        var self = this; 
        if (self.$.field.traversal()) {
          if (value) {
            value.__shell = self;
          }
          if (self.get() && ! value) {
            self.get().__shell = null;
          }
        }
        return self.$.value = value;
      };

      this._path = function(_) {
        var self = this; 
        return self.$.owner._path().field(self.$.field.name());
      };

      this.__delete_obj = function(mobj) {
        var self = this; 
        if (self.get() == mobj) {
          return self.set(null);
        }
      };
    });

  var Many = MakeClass(Field, [RefHelpers, Enumerable],
    function() {
    },
    function(super$) {
      this.get = function() {
        var self = this; 
        return self;
      };

      this.set = function() {
        var self = this; 
        return self.raise(S("Cannot assign to many-valued field ", self.$.field.name()));
      };

      this.init = function(values) {
        var self = this; 
        return values.each(function(value) {
          return self.push(value);
        });
      };

      this.__value = function() {
        var self = this; 
        return self.$.value;
      };

      this._get = function(key) {
        var self = this; 
        return self.__value()._get(key);
      };

      this.empty_P = function() {
        var self = this; 
        return self.__value().empty_P();
      };

      this.length = function() {
        var self = this; 
        return self.__value().length;
      };

      this.to_s = function() {
        var self = this; 
        return self.__value().to_s();
      };

      this.clear = function() {
        var self = this; 
        return self.__value().clear();
      };

      this.connected_P = function() {
        var self = this; 
        return self.$.owner;
      };

      this.has_key_P = function(key) {
        var self = this; 
        return self.keys().include_P(key);
      };

      this.check = function(mobj) {
        var self = this; 
        if (self.connected_P()) {
          return super$.check.call(self, mobj);
        }
      };

      this.notify = function(old, new_V) {
        var self = this; 
        if (self.connected_P()) {
          return super$.notify.call(self, old, new_V);
        }
      };

      this.__delete_obj = function(mobj) {
        var self = this; 
        if (self.values().include_P(mobj)) {
          return self.delete(mobj);
        }
      };

      this.connect = function(mobj, shell) {
        var self = this; 
        if (self.connected_P() && self.$.field.traversal()) {
          return mobj.__shell = shell;
        }
      };
    });

  var Set = MakeClass(Many, [SetUtils],
    function() {
    },
    function(super$) {
      this.initialize = function(owner, field, key) {
        var self = this; 
        super$.initialize.call(self, owner, field);
        self.$.value = new EnsoHash ( { } );
        return self.$.key = key;
      };

      this.each = function(block) {
        var self = this; 
        return self.__value().each_value(block);
      };

      this.each_pair = function(block) {
        var self = this; 
        return self.__value().each_pair();
      };

      this.find_first_pair = function(block) {
        var self = this; 
        return self.__value().find_first_pair();
      };

      this.values = function() {
        var self = this; 
        return self.__value().values();
      };

      this.keys = function() {
        var self = this; 
        return self.__value().keys();
      };

      this._recompute_hash_in_place = function() {
        var self = this; 
        var nval;
        nval = new EnsoHash ( { } );
        self.$.value.each(function(k, v) {
          return nval._set(v._get(self.$.key.name()), v);
        });
        self.$.value = nval;
        return self;
      };

      this.push = function(mobj) {
        var self = this; 
        var key;
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
      };

      this._set = function(index, mobj) {
        var self = this; 
        return self.push(mobj);
      };

      this.delete = function(mobj) {
        var self = this; 
        var key;
        key = mobj._get(self.$.key.name());
        if (self.$.value.has_key_P(key)) {
          self.notify(self.$.value._get(key), null);
          return self.__delete(mobj);
        }
      };

      this._path = function(mobj) {
        var self = this; 
        return self.$.owner._path().field(self.$.field.name()).key(mobj._get(self.$.key.name()));
      };

      this.__insert = function(mobj) {
        var self = this; 
        self.connect(mobj, self);
        return self.$.value._set(mobj._get(self.$.key.name()), mobj);
      };

      this.__delete = function(mobj) {
        var self = this; 
        var deleted;
        deleted = self.$.value.delete(mobj._get(self.$.key.name()));
        self.connect(deleted, null);
        return deleted;
      };
    });

  var List = MakeClass(Many, [ListUtils],
    function() {
    },
    function(super$) {
      this.initialize = function(owner, field) {
        var self = this; 
        super$.initialize.call(self, owner, field);
        return self.$.value = [];
      };

      this._get = function(key) {
        var self = this; 
        return self.__value()._get(key.to_i());
      };

      this.each = function(block) {
        var self = this; 
        return self.__value().each();
      };

      this.each_pair = function(block) {
        var self = this; 
        return self.__value().each_with_index(function(item, i) {
          return block(i, item);
        });
      };

      this.values = function() {
        var self = this; 
        return self.__value();
      };

      this.keys = function() {
        var self = this; 
        return Array.new(function(i) {
          return i;
        }, self.length);
      };

      this.push = function(mobj) {
        var self = this; 
        if (! mobj) {
          self.raise("Cannot insert nil into list");
        }
        self.check(mobj);
        self.notify(null, mobj);
        self.__insert(mobj);
        return self;
      };

      this._set = function(index, mobj) {
        var self = this; 
        var old;
        if (! mobj) {
          self.raise("Cannot insert nil into list");
        }
        old = self.__value()._get(index.to_i());
        if (old != mobj) {
          self.check(mobj);
          self.notify(null, mobj);
          self.__value()._set(index.to_i(), mobj);
          if (old) {
            self.notify(old, null);
          }
        }
        return self;
      };

      this.delete = function(mobj) {
        var self = this; 
        var deleted;
        deleted = self.__delete(mobj);
        if (deleted) {
          self.notify(deleted, null);
        }
        return deleted;
      };

      this.insert = function(index, mobj) {
        var self = this; 
        if (! mobj) {
          self.raise("Cannot insert nil into list");
        }
        self.check(mobj);
        self.notify(null, mobj);
        self.$.value.insert(index.to_i(), mobj);
        return self;
      };

      this._path = function(mobj) {
        var self = this; 
        return self.$.owner._path().field(self.$.field.name()).index(self.$.value.index(mobj));
      };

      this.__insert = function(mobj) {
        var self = this; 
        self.connect(mobj, self);
        return self.$.value.push(mobj);
      };

      this.__delete = function(mobj) {
        var self = this; 
        var deleted;
        deleted = self.$.value.delete(mobj);
        self.connect(deleted, null);
        return deleted;
      };
    });

  Factory = {
    new: function(schema) {
      return SchemaFactory.new(schema);
    },

    SchemaFactory: SchemaFactory,
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
  return Factory;
})
