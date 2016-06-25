define([], (function () {
  var Constraints;
  var ConstraintSystem = MakeClass("ConstraintSystem", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function () {
      var self = this;
      (self.$.vars = (new EnsoHash({
        
      })));
      return (self.$.number = 0);
    }));
    (this.var = (function (name, value) {
      var self = this;
      (name = (((typeof name) !== "undefined") ? name : S("v", self.$.number, "")));
      (value = (((typeof value) !== "undefined") ? value : null));
      (self.$.number += 1);
      return Variable.new(name, value);
    }));
    (this.value = (function (n) {
      var self = this;
      return self.var(S("(", n, ")"), n);
    }));
  }));
  var Constant = MakeClass("Constant", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (val) {
      var self = this;
      return (self.$.value = val);
    }));
    (this.add_listener = (function (l) {
      var self = this;
    }));
    (this.internal_evaluate = (function (path) {
      var self = this;
      return self.$.value;
    }));
    (this.value = (function () {
      var self = this;
      return self.$.value;
    }));
    (this.to_i = (function () {
      var self = this;
      return self.value().to_i();
    }));
    (this.to_s = (function () {
      var self = this;
      return ((self.value() == null) ? "nil" : self.value().to_s());
    }));
    (this.to_str = (function () {
      var self = this;
      return self.value().to_s();
    }));
    (this.to_ary = (function () {
      var self = this;
      return [self];
    }));
  }));
  var TrueClass = MakeClass("TrueClass", null, [], (function () {
  }), (function (super$) {
    (this.test = (function (a, b) {
      var self = this;
      return a;
    }));
  }));
  var FalseClass = MakeClass("FalseClass", null, [], (function () {
  }), (function (super$) {
    (this.test = (function (a, b) {
      var self = this;
      return b;
    }));
  }));
  var Variable = MakeClass("Variable", Constant, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (name, val) {
      var self = this;
      (val = (((typeof val) !== "undefined") ? val : null));
      super$.initialize.call(self, val);
      (self.$.name = name);
      (self.$.dependencies = []);
      (self.$.vars = []);
      return (self.$.bounds = []);
    }));
    (this.add = (function (other) {
      var self = this;
      return self.define_result("add", other);
    }));
    (this.sub = (function (other) {
      var self = this;
      return self.define_result("sub", other);
    }));
    (this.mul = (function (other) {
      var self = this;
      return self.define_result("mul", other);
    }));
    (this.div = (function (other) {
      var self = this;
      return self.define_result("div", other);
    }));
    (this.round = (function () {
      var self = this;
      return self.define_result("round");
    }));
    (this.to_int = (function () {
      var self = this;
      return self.define_result("to_int");
    }));
    (this.max = (function (other) {
      var self = this;
      (other = (((typeof other) !== "undefined") ? other : self.raise("MAX WITH UNDEFINED")));
      if (System.test_type(other, Variable)) {
        other.add_listener(self);
      }
      return self.$.bounds.push(other);
    }));
    (this.test = (function (a, b) {
      var self = this;
      var var_V;
      (var_V = Variable.new(S("test", self.to_s(), "")));
      var_V.internal_define((function (v, ra, rb) {
        return v.test(ra, rb);
      }), self, a, b);
      return var_V;
    }));
    (this.new_var_method = (function (block) {
      var self = this;
      var var_V;
      (var_V = Variable.new(S("p", self.to_s(), "")));
      var_V.internal_define(block, self);
      return var_V;
    }));
    (this.eql_P = (function (x) {
      var self = this;
      return self.method_missing("eql?", x);
    }));
    (this.define_result = (function (m) {
      var self = this;
      var args = compute_rest_arguments(arguments, this.define_result.length);
      var var_V;
      if ((!["add", "sub", "mul", "div", "round", "to_int"].include_P(m))) {
        self.raise(S("undefined method ", m, ""));
      }
      (var_V = Variable.new(S("p", self.to_s(), "", args.to_s(), "")));
      var_V.internal_define.apply(var_V, [(function () {
        var values = compute_rest_arguments(arguments, 0);
        return self.do_op.apply(self, [m].concat(values));
      }), self].concat(args));
      return var_V;
    }));
    (this.do_op = (function (op) {
      var self = this;
      var values = compute_rest_arguments(arguments, this.do_op.length);
      switch ((function () {
        return op;
      })()) {
        case "to_int":
         return values._get(0).to_int();
        case "round":
         return values._get(0).round();
        case "div":
         return (values._get(0) / values._get(1));
        case "mul":
         return (values._get(0) * values._get(1));
        case "sub":
         return (values._get(0) - values._get(1));
        case "add":
         return (values._get(0) + values._get(1));
      }
          
    }));
    (this.internal_define = (function (block) {
      var self = this;
      var vars = compute_rest_arguments(arguments, this.internal_define.length);
      if (self.$.block) {
        self.raise("DOUBLE defined Var");
      }
      (self.$.vars = vars.map((function (v) {
        if ((v == null)) { 
          return self.raise(S("Unbound variable ", v.toString(), "")); 
        }
        else { 
          if (System.test_type(v, Constant)) { 
            return v; 
          }
          else { 
            return Constant.new(v);
          }
        }
      })));
      self.$.vars.each((function (v) {
        return v.add_listener(self);
      }));
      return (self.$.block = block);
    }));
    (this.add_listener = (function (x) {
      var self = this;
      return self.$.dependencies.push(x);
    }));
    (this.value = (function () {
      var self = this;
      if ((!self.$.value)) {
        self.internal_evaluate();
      }
      return self.$.value;
    }));
    (this.set_value = (function (x) {
      var self = this;
      (self.$.block = null);
      self.internal_notify_change();
      return (self.$.value = x);
    }));
    (this.internal_notify_change = (function () {
      var self = this;
      self.$.dependencies.each((function (var_V) {
        return var_V.internal_notify_change();
      }));
      if ((!(self.$.block == null))) {
        return (self.$.value = null);
      }
    }));
    (this.internal_evaluate = (function (path) {
      var self = this;
      (path = (((typeof path) !== "undefined") ? path : []));
      var vals;
      if (path.include_P(self)) {
        self.raise(S("circular constraint ", path.map("to_s"), ""));
      }
      if (self.$.block) {
        path.push(self);
        (vals = self.$.vars.map((function (var_V) {
          var val;
          (val = var_V.internal_evaluate(path));
          if ((val == null)) {
            puts(S("WARNING: undefined variable '", var_V, "'"));
            (val = 10);
          }
          return val;
        })));
        path.pop();
        (self.$.value = self.$.block.apply(self.$.block, [].concat(vals)));
      }
      self.$.bounds.each((function (b) {
        var val;
        if (System.test_type(b, Variable)) { 
          (val = b.value()); 
        }
        else { 
          (val = b);
        }
        if (((self.$.value == null) || (self.$.value < val))) {
          return (self.$.value = val);
        }
      }));
      return self.$.value;
    }));
  }));
  (Constraints = {
    Constant: Constant,
    TrueClass: TrueClass,
    ConstraintSystem: ConstraintSystem,
    FalseClass: FalseClass,
    Variable: Variable
  });
  return Constraints;
}));