define([
  "core/semantics/code/interpreter"
],
function(Interpreter) {
  var ImmutableFactory ;

  var ImmutableList = MakeClass("ImmutableList", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(items) {
        var self = this; 
        return self.$.items = items;
      };

      this.each = function(block) {
        var self = this; 
        return self.$.items.each(block);
      };
    });

  var ManagedObjectBase = MakeClass("ManagedObjectBase", null, [],
    function() {
    },
    function(super$) {
    });

  var ImmutableFactory = MakeClass("ImmutableFactory", null, [Interpreter.Dispatcher],
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
        return self.setup(self.$.schema);
      };

      this.setup = function(obj) {
        var self = this; 
        return self.dispatch_obj("setup", obj);
      };

      this._get = function(name) {
        var self = this; 
        return self.send(name);
      };

      this.register = function(root) {
        var self = this; 
        return self.$.root = root;
      };

      this.setup_Schema = function(schema) {
        var self = this; 
        return schema.classes().each(function(klass) {
          return self.setup(klass);
        });
      };

      this.setup_Class = function(klass) {
        var self = this; 
        var c;
        c = Class.new(ManagedObjectBase);
        self.dynamic_bind(function() {
          return klass.all_fields().each(function(field) {
            return self.setup(field);
          });
        }, new EnsoHash ({ class: c }));
        self._create_factory_method(klass, c);
        return self._create_initialize_method(klass, c);
      };

      this._create_factory_method = function(klass, c) {
        var self = this; 
        return self.define_singleton_method(function() {
          var args = compute_rest_arguments(arguments, 0);
          return c.new.apply(c, [self].concat(args));
        }, klass.name());
      };

      this._create_initialize_method = function(klass, c) {
        var self = this; 
        var interpreter, key, val;
        interpreter = self;
        return c.define_method(function(factory) {
          var args = compute_rest_arguments(arguments, 1);
          return klass.fields().each_with_index(function(fld, i) {
            if (i >= args.size() && ! fld.optional()) {
              self.raise("Creating immutable object without initializing all required fields");
            }
            if (fld.many()) {
              if (key = Schema.class_key(fld.type())) {
                val = ImmutableSet.new(i < args.size()
                  ? args._get(i)
                  : []);
              } else {
                val = ImmutableList.new(i < args.size()
                  ? args._get(i)
                  : []);
              }
            } else {
              val = i < args.size()
                ? args._get(i)
                : interpreter.default_field_value(fld);
            }
            return self.instance_variable_set(S("@", fld.name()), val);
          });
        }, "initialize");
      };

      this.setup_Field = function(fld) {
        var self = this; 
        if (fld.computed()) {
          return self.setup_computed(self.$.D._get("class"), fld);
        } else {
          return self.define_getter(self.$.D._get("class"), fld);
        }
      };

      this.define_getter = function(c, fld) {
        var self = this; 
        return c.define_method(function() {
          return self.instance_variable_get(S("@", fld.name()));
        }, fld.name().to_sym());
      };

      this.setup_computed = function(c, fld) {
        var self = this; 
        var exp, computed, val;
        exp = fld.computed();
        computed = false;
        return c.define_method(function() {
          if (! computed) {
            val = Impl.eval(exp, new EnsoHash ({ env: Env.ObjEnv.new(self) }));
            computed = true;
          }
          return val;
        }, fld.name());
      };
    });

  ImmutableFactory = {
    new: function(schema) {
      var self = this; 
      return ImmutableFactory.new(schema);
    },

    ImmutableList: ImmutableList,
    ManagedObjectBase: ManagedObjectBase,
    ImmutableFactory: ImmutableFactory,

  };
  return ImmutableFactory;
})
