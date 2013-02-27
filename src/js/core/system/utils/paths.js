define([
  "core/semantics/code/interpreter"
],
function(Interpreter) {
  var Paths ;

  var Path = MakeClass("Path", null, [Interpreter.Dispatcher],
    function() {
      this.set_factory = function(factory) {
        var self = this; 
        return self.$.factory = factory;
      };
    },
    function(super$) {
      this.initialize = function(path) {
        var self = this; 
        return self.$.path = path || self._class_.$.factory.EVar("root");
      };

      this.field = function(name) {
        var self = this; 
        self.$.path = self._class_.$.factory.EField(self.$.path, name);
        return self;
      };

      this.key = function(key) {
        var self = this; 
        return self.index(key);
      };

      this.index = function(index) {
        var self = this; 
        self.$.path = self._class_.$.factory.ESubscript(self.$.path, self._class_.$.factory.EStrConst(index));
        return self;
      };

      this.deref_P = function(scan, root) {
        var self = this; 
        if (root === undefined) root = self.scan();
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
    new: function(start) {
      if (start === undefined) start = null;
      return Path.new(start);
    },

    Path: Path,

  };
  return Paths;
})
