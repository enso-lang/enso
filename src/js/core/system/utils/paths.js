define(["core/semantics/code/interpreter", "core/schema/tools/equals"], (function (Interpreter, Equals) {
  var Paths;
  var Path = MakeClass("Path", null, [Interpreter.Dispatcher], (function () {
    (this.set_factory = (function (factory) {
      var self = this;
      return Path.new(factory.EVar("root")).set_factory(factory);
    }));
  }), (function (super$) {
    (this.path = (function () {
      return this.$.path;
    }));
    (this.set_factory = (function (factory) {
      var self = this;
      return (self._class_.$.factory = factory);
    }));
    (this.initialize = (function (path) {
      var self = this;
      (path = (((typeof path) !== "undefined") ? path : self._class_.$.factory.EVar("root")));
      return (self.$.path = (path ? path : self._class_.$.factory.EVar("root")));
    }));
    (this.field = (function (name) {
      var self = this;
      return Path.new(self._class_.$.factory.EField(self.$.path, name));
    }));
    (this.key = (function (key) {
      var self = this;
      return Path.new(self._class_.$.factory.ESubscript(self.$.path, self._class_.$.factory.EStrConst(key)));
    }));
    (this.index = (function (index) {
      var self = this;
      return Path.new(self._class_.$.factory.ESubscript(self.$.path, self._class_.$.factory.EIntConst(index)));
    }));
    (this.equals = (function (other) {
      var self = this;
      return Equals.equals(self.$.path, other.path());
    }));
    (this.deref_P = (function (root) {
      var self = this;
      try {return (!(self.deref(root) == null));
           
      }
      catch (caught$960) {
        
          return false;
      }
    }));
    (this.to_s = (function () {
      var self = this;
      return self.to_s_path(self.$.path);
    }));
    (this.to_s_path = (function (path) {
      var self = this;
      return self.dispatch_obj("to_s", path);
    }));
    (this.to_s_EVar = (function (obj) {
      var self = this;
      return obj.name();
    }));
    (this.to_s_EConst = (function (obj) {
      var self = this;
      return obj.val();
    }));
    (this.to_s_EField = (function (obj) {
      var self = this;
      return S("", self.to_s_path(obj.e()), ".", obj.fname(), "");
    }));
    (this.to_s_ESubscript = (function (obj) {
      var self = this;
      return S("", self.to_s_path(obj.e()), "[", self.to_s_path(obj.sub()), "]");
    }));
    (this.deref = (function (root) {
      var self = this;
      return self.dynamic_bind((function () {
        return self.eval();
      }), (new EnsoHash({
        root: root
      })));
    }));
    (this.eval = (function (path) {
      var self = this;
      (path = (((typeof path) !== "undefined") ? path : self.$.path));
      return self.dispatch_obj("eval", path);
    }));
    (this.eval_EVar = (function (obj) {
      var self = this;
      if ((!self.$.D.include_P(obj.name().to_sym()))) {
        self.raise(S("undefined variable ", obj.name(), ""));
      }
      return self.$.D._get(obj.name().to_sym());
    }));
    (this.eval_EConst = (function (obj) {
      var self = this;
      return obj.val();
    }));
    (this.eval_EField = (function (obj) {
      var self = this;
      return self.eval(obj.e())._get(obj.fname());
    }));
    (this.eval_ESubscript = (function (obj) {
      var self = this;
      return self.eval(obj.e())._get(self.eval(obj.sub()));
    }));
    (this.assign = (function (root, val) {
      var self = this;
      var obj;
      (obj = self.$.path);
      if (obj.EField_P()) { 
        return self.dynamic_bind((function () {
          return self.eval(obj.e())._set(obj.fname(), val);
        }), (new EnsoHash({
          root: root
        }))); 
      }
      else { 
        if (obj.ESubscript_P()) { 
          return self.dynamic_bind((function () {
            return self.eval(obj.e())._set(self.eval(obj.sub()), val);
          }), (new EnsoHash({
            root: root
          }))); 
        } 
        else {
             }
      }
    }));
    (this.insert = (function (root, val) {
      var self = this;
      var obj;
      (obj = self.$.path);
      if (obj.EField_P()) { 
        return self.dynamic_bind((function () {
          return self.eval(obj.e())._set(obj.fname(), val);
        }), (new EnsoHash({
          root: root
        }))); 
      }
      else { 
        if (obj.ESubscript_P()) { 
          return self.dynamic_bind((function () {
            return self.eval(obj.e()).insert(self.eval(obj.sub()), val);
          }), (new EnsoHash({
            root: root
          }))); 
        } 
        else {
             }
      }
    }));
    (this.delete = (function (root) {
      var self = this;
      var obj;
      (obj = self.$.path);
      if (obj.EField_P()) { 
        return self.dynamic_bind((function () {
          return self.eval(obj.e())._set(obj.fname(), null);
        }), (new EnsoHash({
          root: root
        }))); 
      }
      else { 
        if (obj.ESubscript_P()) { 
          return self.dynamic_bind((function () {
            return self.eval(obj.e()).delete(self.eval(obj));
          }), (new EnsoHash({
            root: root
          }))); 
        } 
        else {
             }
      }
    }));
    (this.type = (function (root, obj) {
      var self = this;
      (obj = (((typeof obj) !== "undefined") ? obj : self.$.path));
      if (obj.EField_P()) { 
        return self.dynamic_bind((function () {
          return self.eval(obj.e()).schema_class().fields()._get(obj.fname());
        }), (new EnsoHash({
          root: root
        }))); 
      }
      else { 
        if (obj.ESubscript_P()) { 
          return self.type(root, obj.e()); 
        } 
        else {
             }
      }
    }));
    (this.assign_and_coerce = (function (root, value) {
      var self = this;
      var obj, fld;
      if ((!self.lvalue_P())) {
        self.raise(S("Can only assign to lvalues not to ", self, ""));
      }
      (obj = self.owner().deref(root));
      (fld = obj.schema_class().fields()._get(self.last().name()));
      if (fld.type().Primitive_P()) {
        switch ((function () {
          return fld.type().name();
        })()) {
          case "real":
           (value = value.to_f());
           break;
          case "bool":
           (value = ((value.to_s() == "true") ? true : false));
           break;
          case "int":
           (value = value.to_i());
           break;
          case "str":
           (value = value.to_s());
           break;
          default:
           self.raise(S("Unknown primitive type: ", fld.type().name(), ""));
        }
            
      }
      return self.owner().deref(root)._set(self.last().name(), value);
    }));
  }));
  (Paths = {
    new: (function (start) {
      var self = this;
      (start = (((typeof start) !== "undefined") ? start : null));
      return Path.new(start);
    }),
    Path: Path
  });
  return Paths;
}));