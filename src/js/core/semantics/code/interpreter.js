define([], (function () {
  var Interpreter;
  var DynamicPropertyStack = MakeClass("DynamicPropertyStack", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function () {
      var self = this;
      (self.$.current = (new EnsoHash({
        
      })));
      return (self.$.stack = []);
    }));
    (this._get = (function (name) {
      var self = this;
      return self.$.current._get(name);
    }));
    (this.include_P = (function (name) {
      var self = this;
      return self.$.current.include_P(name);
    }));
    (this.keys = (function () {
      var self = this;
      return self.$.current.keys();
    }));
    (this._bind = (function (field, value) {
      var self = this;
      var old;
      if (self.$.current.has_key_P(field)) { 
        (old = self.$.current._get(field)); 
      }
      else { 
        (old = "undefined");
      }
      self.$.stack.push([field, old]);
      return self.$.current._set(field, value);
    }));
    (this._pop = (function (n) {
      var self = this;
      (n = (((typeof n) !== "undefined") ? n : 1));
      var parts;
      while ((n > 0)) {
        (parts = self.$.stack.pop());
        if ((parts._get(1) == "undefined")) { 
          self.$.current.delete(parts._get(0)); 
        }
        else { 
          self.$.current._set(parts._get(0), parts._get(1));
        }
        (n -= 1);
      }
    }));
    (this.to_s = (function () {
      var self = this;
      return self.$.current.to_s();
    }));
  }));
  var Dispatcher = MakeMixin([], (function () {
    (this.init = (function () {
      var self = this;
      if ((!self.$.D)) {
        (self.$.D = DynamicPropertyStack.new());
      }
      return (self.$.indent = null);
    }));
    (this.dynamic_bind = (function (block, fields) {
      var self = this;
      (fields = (((typeof fields) !== "undefined") ? fields : (new EnsoHash({
        
      }))));
      var result;
      if ((!self.$.D)) {
        (self.$.D = DynamicPropertyStack.new());
      }
      fields.each((function (key, value) {
        if (self.$.debug) {
          puts(S("BIND ", key, "=", value, ""));
        }
        return self.$.D._bind(key, value);
      }));
      (result = block());
      self.$.D._pop(fields.size());
      return result;
    }));
    (this.wrap = (function (operation, outer, obj) {
      var self = this;
      var method, init_done, type, result;
      (init_done = self.$.init);
      if ((!init_done)) {
        self.init();
      }
      (self.$.init = true);
      (type = obj.schema_class());
      (method = S("", outer, "_", type.name(), "").to_s());
      if ((!self.respond_to_P(method))) {
        (method = self.find(outer, type));
      }
      if ((!method)) {
        (method = S("", outer, "_?").to_s());
        if ((!self.respond_to_P(method))) {
          self.raise(S("Missing method in interpreter for ", outer, "_", type.name(), "(", obj, ")"));
        }
      }
      (result = null);
      self.send((function () {
        return (result = self.dispatch_obj(operation, obj));
      }), method, obj);
      if ((!init_done)) {
        (self.$.init = false);
      }
      return result;
    }));
    (this.dispatch_obj = (function (operation, obj) {
      var self = this;
      var method, init_done, type, result;
      (init_done = self.$.init);
      if ((!init_done)) {
        self.init();
      }
      (self.$.init = true);
      (type = obj.schema_class());
      (method = S("", operation, "_", type.name(), "").to_s());
      if ((!self.respond_to_P(method))) {
        (method = self.find(operation, type));
      }
      if ((!method)) {
        (method = S("", operation, "_?").to_s());
        if ((!self.respond_to_P(method))) {
          self.raise(S("Missing method in interpreter for ", operation, "_", type.name(), "(", obj, ")"));
        }
      }
      if (self.$.indent) {
        puts(S("", (" " * self.$.indent), "", method, ""));
        (self.$.indent = (self.$.indent + 1));
      }
      (result = self.send(method, obj));
      if (self.$.indent) {
        puts(S("", (" " * self.$.indent), "=", result, ""));
        (self.$.indent = (self.$.indent - 1));
      }
      if ((!init_done)) {
        (self.$.init = false);
      }
      return result;
    }));
    (this.find = (function (operation, type) {
      var self = this;
      var method;
      (method = S("", operation, "_", type.name(), "").to_s());
      if (self.respond_to_P(method)) { 
        return method; 
      }
      else { 
        return type.supers().find_first((function (p) {
          return self.find(operation, p);
        }));
      }
    }));
  }));
  (Interpreter = {
    Dispatcher: Dispatcher,
    DynamicPropertyStack: DynamicPropertyStack
  });
  return Interpreter;
}));