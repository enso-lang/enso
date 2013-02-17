define([
],
function() {

  var Interpreter ;
  var DynamicPropertyStack = MakeClass( {
    initialize: function() {
      var self = this; 
      var super$ = this.super$.initialize;
      self.$.current = new EnsoHash ( { } );
      return self.$.stack = [];
    },

    _get: function(name) {
      var self = this; 
      var super$ = this.super$._get;
      return self.$.current._get(name);
    },

    _bind: function(field, value) {
      var self = this; 
      var old;
      var super$ = this.super$._bind;
      old = self.$.current._get(field);
      self.$.stack.push([field, old]);
      return self.$.current ._set( field , value );
    },

    _pop: function(n) {
      var self = this; 
      if (n === undefined) n = 1;
      var parts;
      var super$ = this.super$._pop;
      while (n > 0) {
        parts = self.$.stack.pop();
        self.$.current ._set( parts._get(0) , parts._get(1) );
        n = n - 1;
      }
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.current.to_s();
    }
  });

  var Dispatcher = MakeMixin({
    _: function() { return this.$._ },
    set__: function(val) { this.$._  = val },

    dynamic_bind: function(block, fields) {
      var self = this; 
      var result;
      var super$ = this.super$.dynamic_bind;
      if (! self.$.D) {
        self.$.D = DynamicPropertyStack.new();
      }
      fields.each(function(key, value) {
        return self.$.D._bind(key, value);
      });
      result = block.call();
      self.$.D._pop(fields.size());
      return result;
    },

    dispatch: function(operation, obj) {
      var self = this; 
      var type, method, params;
      var super$ = this.super$.dispatch;
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
        return self.send(method, type, obj, self.$.D);
      } else {
        params = type.fields().map(function(f) {
          return obj._get(f.name());
        });
        return self.send .call_rest_args$(self, method, params );
      }
    },

    dispatch_obj: function(operation, obj) {
      var self = this; 
      var type, method;
      var super$ = this.super$.dispatch_obj;
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
      return self.send(method, obj);
    },

    find: function(operation, type) {
      var self = this; 
      var method;
      var super$ = this.super$.find;
      method = S(operation, "_", type.name()).to_s();
      if (self.respond_to_P(method)) {
        return method;
      } else {
        return type.supers().find_first(function(p) {
          return self.find(operation, p);
        });
      }
    }
  });

  Interpreter = {
    DynamicPropertyStack: DynamicPropertyStack,
    Dispatcher: Dispatcher,

  };
  return Interpreter;
})
