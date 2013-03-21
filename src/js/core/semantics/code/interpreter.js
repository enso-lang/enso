define([
],
function() {
  var Interpreter ;
  var DynamicPropertyStack = MakeClass("DynamicPropertyStack", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
        self.$.current = new EnsoHash ({ });
        return self.$.stack = [];
      };

      this._get = function(name) {
        var self = this; 
        return self.$.current._get(name);
      };

      this.include_P = function(name) {
        var self = this; 
        return self.$.current.include_P(name);
      };

      this.keys = function() {
        var self = this; 
        return self.$.current.keys();
      };

      this._bind = function(field, value) {
        var self = this; 
        var old;
        old = self.$.current._get(field);
        self.$.stack.push([field, old]);
        return self.$.current._set(field, value);
      };

      this._pop = function(n) {
        var self = this; 
        if (n === undefined) n = 1;
        var parts;
        while (n > 0) {
          parts = self.$.stack.pop();
          self.$.current._set(parts._get(0), parts._get(1));
          n = n - 1;
        }
      };

      this.to_s = function() {
        var self = this; 
        return self.$.current.to_s();
      };
    });

  var Dispatcher = MakeMixin([], function() {
    this.debug = function() {
      var self = this; 
      self.$.debug = true;
      if (! self.$.indent) {
        return self.$.indent = 0;
      }
    };

    this.dynamic_bind = function(block, fields) {
      var self = this; 
      var result;
      if (! self.$.D) {
        self.$.D = DynamicPropertyStack.new();
      }
      fields.each(function(key, value) {
        if (self.$.debug) {
          console.log("BIND " + key + "=" + value);
        }
        return self.$.D._bind(key, value);
      });
      result = block();
      self.$.D._pop(fields.size());
      return result;
    };

    this.wrap = function(operation, outer, obj) {
      var self = this; 
      return self.dispatch_obj(function() {
        return self.dispatch_obj(operation, obj);
      }, outer, obj);
    };

    this.dispatch_obj = function(operation, obj) {
      var self = this; 
      var type, method, result;
      type = obj.schema_class();
      method = S(operation, "_", type.name()).to_s();
      if (! self.respond_to_P(method)) {
        method = self.find(operation, type);
      }
      if (! method) {
        method = S(operation, "_?").to_s();
        if (! self.respond_to_P(method)) {
          self.raise(S("Missing method in interpreter for ", operation, "_", type.name(), "(", obj, ")"));
        }
      }
      if (self.$.debug) {
        System.stderr().push(S(" ".repeat(self.$.indent), ">", operation, " ", obj, "\\n"));
        self.$.indent = self.$.indent + 1;
      }
      result = self.send(method, obj);
      if (self.$.debug) {
        self.$.indent = self.$.indent - 1;
        System.stderr().push(S(" ".repeat(self.$.indent), "= ", result, "\\n"));
      }
      return result;
    };

    this.find = function(operation, type) {
      var self = this; 
      var method;
      method = S(operation, "_", type.name()).to_s();
      if (self.respond_to_P(method)) {
        return method;
      } else {
        return type.supers().find_first(function(p) {
          return self.find(operation, p);
        });
      }
    };
  });

  Interpreter = {
    DynamicPropertyStack: DynamicPropertyStack,
    Dispatcher: Dispatcher,

  };
  return Interpreter;
})
