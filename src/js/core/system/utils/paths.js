define([
  "core/schema/code/factory",
  "core/system/load/load",
  "core/semantics/code/interpreter"
],
function(Factory, Load, Interpreter) {
  var Paths ;

  var Path = MakeClass("Path", null, [Interpreter.Dispatcher],
    function() {
    },
    function(super$) {
      this.initialize = function(path) {
        var self = this; 
        self.$.factory = Factory.new(Load.load("schema.schema"));
        return self.$.path = path || self.$.factory.EVar("root");
      };

      this.parse = function(str) {
        var self = this; 
        var str, n;
        str = str.gsub("\\", "");
        str.split(".").each(function(part) {
          if ((n = part.index("[")) && part.slice(- 1) == "]") {
            self.field(part.slice(0, n));
            return self.index(part.slice(n + 1, (part.length - n) - 2));
          } else if (part != "") {
            return self.field(part);
          }
        });
        return self;
      };

      this.field = function(name) {
        var self = this; 
        self.$.path = self.$.factory.EField(self.$.path, name);
        return self;
      };

      this.key = function(key) {
        var self = this; 
        return self.index(key);
      };

      this.index = function(index) {
        var self = this; 
        self.$.path = self.$.factory.ESubscript(self.$.path, self.$.factory.EStrConst(index));
        return self;
      };

      this.deref_P = function(scan, root) {
        var self = this; 
        if (root === undefined) root = scan;
        var root;
        try {
          return self.deref(scan, root = scan);
        } catch ( DUMMY ) {
          return false;
        }
      };

      this.to_s = function() {
        var self = this; 
        return self.to_s_path(self.$.path);
      };

      this.to_s_path = function(path) {
        var self = this; 
        return self.dispatch_obj("to_s", path);
      };

      this.to_s_EVar = function(obj) {
        var self = this; 
        return obj.name();
      };

      this.to_s_EConst = function(obj) {
        var self = this; 
        return obj.val();
      };

      this.to_s_EField = function(obj) {
        var self = this; 
        return S(self.to_s_path(obj.e()), ".", obj.fname());
      };

      this.to_s_ESubscript = function(obj) {
        var self = this; 
        return S(self.to_s_path(obj.e()), "[", self.to_s_path(obj.sub()), "]");
      };

      this.deref = function(root) {
        var self = this; 
        return self.dynamic_bind(function() {
          return self.eval();
        }, new EnsoHash ( { root: root } ));
      };

      this.eval = function(path) {
        var self = this; 
        if (path === undefined) path = self.$.path;
        return self.dispatch_obj("eval", path);
      };

      this.eval_EVar = function(obj) {
        var self = this; 
        return self.$.D._get(obj.name().to_sym());
      };

      this.eval_EConst = function(obj) {
        var self = this; 
        return obj.val();
      };

      this.eval_EField = function(obj) {
        var self = this; 
        return self.eval(obj.e())._get(obj.fname());
      };

      this.eval_ESubscript = function(obj) {
        var self = this; 
        return self.eval(obj.e())._get(self.eval(obj.sub()));
      };

      this.assign = function(root, obj) {
        var self = this; 
        if (! self.lvalue_P()) {
          self.raise(S("Can only assign to lvalues not to ", self));
        }
        return self.owner().deref(root)._set(self.last().name(), obj);
      };

      this.assign_and_coerce = function(root, value) {
        var self = this; 
        var obj, fld, value;
        if (! self.lvalue_P()) {
          self.raise(S("Can only assign to lvalues not to ", self));
        }
        obj = self.owner().deref(root);
        fld = obj.schema_class().fields()._get(self.last().name());
        if (fld.type().Primitive_P()) {
          value = fld.type().name() == "str"
            ? value.to_s()
            : (fld.type().name() == "int"
              ? value.to_i()
              : (fld.type().name() == "bool"
                ? (value.to_s() == "true"
                  ? true
                  : false)
                : (fld.type().name() == "real"
                  ? value.to_f()
                  : self.raise(S("Unknown primitive type: ", fld.type().name())))));
        }
        return self.owner().deref(root)._set(self.last().name(), value);
      };
    });

  Paths = {
    parse: function(str) {
      return Paths.new().parse(str);
    },

    new: function(start) {
      if (start === undefined) start = null;
      return Path.new(start);
    },

    Path: Path,

  };
  return Paths;
})
