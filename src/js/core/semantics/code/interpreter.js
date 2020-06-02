'use strict'

//// Interpreter ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Interpreter;

class DynamicPropertyStack {
  static new(...args) { return new DynamicPropertyStack(...args) };

  constructor() {
    var self = this;
    self.current$ = Enso.EMap.new();
    self.stack$ = [];
  };

  get$(name) {
    var self = this;
    return self.current$.get$(name);
  };

  include_P(name) {
    var self = this;
    return self.current$.include_P(name);
  };

  keys() {
    var self = this;
    return self.current$.keys();
  };

  _bind(field, value) {
    var self = this, old;
    if (self.current$.has_key_P(field)) {
      old = self.current$.get$(field);
    } else {
      old = "undefined";
    }
    self.stack$.push([field, old]);
    return self.current$ .set$(field, value);
  };

  _pop(n = 1) {
    var self = this, parts;
    while (n > 0) {
      parts = self.stack$.pop();
      if (parts.get$(1) == "undefined") {
        self.current$.delete_M(parts.get$(0));
      } else {
        self.current$ .set$(parts.get$(0), parts.get$(1));
      }
      n = n - 1;
    }
  };

  to_s() {
    var self = this;
    return self.current$.to_s();
  };
};

function Dispatcher(parent) {
  return class extends parent {
    init() {
      var self = this;
      if (! self.D$) {
        self.D$ = DynamicPropertyStack.new();
      }
      return self.indent$ = null;
    };

    dynamic_bind(block, fields = Enso.EMap.new()) {
      var self = this, result;
      if (! self.D$) {
        self.D$ = DynamicPropertyStack.new();
      }
      fields.each(function(key, value) {
        return self.D$._bind(key, value);
      });
      result = block();
      self.D$._pop(fields.size_M());
      return result;
    };

    wrap(operation, outer, obj) {
      var self = this, init_done, type, method, result;
      init_done = self.init$;
      if (! init_done) {
        self.init();
      }
      self.init$ = true;
      type = obj.schema_class();
      method = Enso.S(outer, "_", type.name()).to_s();
      if (! self.respond_to_P(method)) {
        method = self.find_op(outer, type);
      }
      if (! method) {
        method = Enso.S(outer, "_?").to_s();
        if (! self.respond_to_P(method)) {
          self.raise(Enso.S("Missing method in interpreter for ", outer, "_", type.name(), "(", obj, ")"));
        }
      }
      result = null;
      self.send(function() {
        return result = self.dispatch_obj(operation, obj);
      }, method, obj);
      if (! init_done) {
        self.init$ = false;
      }
      return result;
    };

    dispatch_obj(operation, obj) {
      var self = this, init_done, type, method, result;
      init_done = self.init$;
      if (! init_done) {
        self.init();
      }
      self.init$ = true;
      type = obj.schema_class();
      method = Enso.S(operation, "_", type.name()).to_s();
      if (! self.respond_to_P(method)) {
        method = self.find_op(operation, type);
      }
      if (! method) {
        method = Enso.S(operation, "_?").to_s();
        if (! self.respond_to_P(method)) {
          self.raise(Enso.S("Missing method in interpreter for ", operation, "_", type.name(), "(", obj, ")"));
        }
      }
      if (self.indent$) {
        STDERR.puts(Enso.S(" " * self.indent$, method));
        self.indent$ = self.indent$ + 1;
      }
      result = self.send(method, obj);
      if (self.indent$) {
        STDERR.puts(Enso.S(" " * self.indent$, "=", result));
        self.indent$ = self.indent$ - 1;
      }
      if (! init_done) {
        self.init$ = false;
      }
      return result;
    };

    find_op(operation, type) {
      var self = this, method;
      method = Enso.S(operation, "_", type.name()).to_s();
      if (self.respond_to_P(method)) {
        return method;
      } else {
        return type.supers().find_first(function(p) {
          return self.find_op(operation, p);
        });
      }
    }; }};

Interpreter = {
  DynamicPropertyStack: DynamicPropertyStack,
  Dispatcher: Dispatcher,
};
module.exports = Interpreter ;
