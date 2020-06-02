'use strict'

//// Impl ////

var cwd = process.cwd() + '/';
var Eval = require(cwd + "core/expr/code/eval.js");
var Lvalue = require(cwd + "core/expr/code/lvalue.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Env = require(cwd + "core/expr/code/env.js");
var Enso = require(cwd + "enso.js");

var Impl;

var eval_M = function(obj, args = Enso.EMap.new({env: Enso.EMap.new()})) {
  var self = this, local_funs, max, min, sum, count, average, sumvariance, p, arr, mid, sorted, nv, interp;
  local_funs = Enso.EMap.new();
  local_funs .set$("MAX", function(...a) {
    max = null;
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          return max = max == null
            ? v
            : [max, v].max();
        });
      } else {
        return max = max == null
          ? b
          : [max, b].max();
      }
    });
    return max;
  });
  local_funs .set$("MIN", function(...a) {
    min = null;
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          return min = min == null
            ? v
            : [min, v].min();
        });
      } else {
        return min = min == null
          ? b
          : [min, b].min();
      }
    });
    return min;
  });
  local_funs .set$("SUM", function(...a) {
    sum = 0;
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          return sum = sum + v;
        });
      } else {
        return sum = sum + b;
      }
    });
    return sum;
  });
  local_funs .set$("COUNT", function(...a) {
    count = null;
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          return count = count == null
            ? 1
            : count + 1;
        });
      } else {
        return count = count == null
          ? 1
          : count + 1;
      }
    });
    return count;
  });
  local_funs .set$("AVERAGE", function(...a) {
    return local_funs.get$("SUM")(...a) / local_funs.get$("COUNT")(...a);
  });
  local_funs .set$("STDEV", function(...a) {
    average = local_funs.get$("AVERAGE")(...a);
    sumvariance = 0;
    count = 0;
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          p = v - average;
          sumvariance = sumvariance + p * p;
          return count = count + 1;
        });
      } else {
        p = b - average;
        sumvariance = sumvariance + p * p;
        return count = count + 1;
      }
    });
    return Math.sqrt(sumvariance / count);
  });
  local_funs .set$("MEDIAN", function(...a) {
    arr = [];
    a.each(function(b) {
      if (Enso.System.test_type(b, Enumerable)) {
        return b.each(function(v) {
          return arr.push(v);
        });
      } else {
        return arr.push(b);
      }
    });
    mid = arr.size_M() / 2;
    sorted = arr.sort();
    if (mid.odd_P()) {
      return sorted.get$(mid);
    } else {
      return 0.5 * (sorted.get$(mid) + sorted.get$(mid - 1));
    }
  });
  nv = Env.HashEnv.new(local_funs, args.get$("env"));
  args .set$("env", nv);
  interp = EvalCommandC.new();
  return interp.dynamic_bind(function() {
    return interp.eval_M(obj);
  }, args);
};

class Closure extends Enso.EnsoBaseClass {
  static new(...args) { return new Closure(...args) };

  static make_closure(body, formals, env, interp) {
    var self = this;
    return Closure.new(body, formals, env, interp).method("call_closure");
  };

  formals() { return this.formals$ };

  body() { return this.body$ };

  constructor(body, formals, env, interp) {
    super();
    var self = this;
    self.body$ = body;
    self.formals$ = formals;
    self.env$ = env;
    self.interp$ = interp;
  };

  call_closure(...params) {
    var self = this, nv, nenv;
    nv = Enso.EMap.new();
    self.formals$.each_with_index(function(f, i) {
      return nv .set$(f, params.get$(i));
    });
    nenv = Env.HashEnv.new(nv, self.env$);
    return self.interp$.dynamic_bind(function() {
      return self.interp$.eval_M(self.body$);
    }, Enso.EMap.new({env: nenv}));
  };

  to_s() {
    var self = this;
    return Enso.S("#<Closure(", self.formals$.map(function(f) {
      return f.name();
    }).join(", "), ") {", self.body$, "}>");
  };
};

function EvalCommand(parent) {
  return class extends Enso.mix(parent, Eval.EvalExpr, Lvalue.LValueExpr, Interpreter.Dispatcher) {
    eval_M(obj) {
      var self = this;
      return self.dispatch_obj("eval", obj);
    };

    eval_ESequence(obj) {
      var self = this;
      return obj.items().each(function(block) {
        return self.eval_M(block);
      });
    };

    eval_EWhile(obj) {
      var self = this;
      while (self.eval_M(obj.cond())) {
        self.eval_M(obj.body());
      }
    };

    eval_EFor(obj) {
      var self = this, env, nenv;
      env = Enso.EMap.new();
      env .set$(obj.var(), null);
      nenv = Env.HashEnv.new(env, self.D$.get$("env"));
      return self.eval_M(obj.list()).each(function(val) {
        nenv .set$(obj.var(), val);
        return self.dynamic_bind(function() {
          return self.eval_M(obj.body());
        }, Enso.EMap.new({env: nenv}));
      });
    };

    eval_EIf(obj) {
      var self = this;
      if (self.eval_M(obj.cond())) {
        return self.eval_M(obj.body());
      } else if (! (obj.body2() == null)) {
        return self.eval_M(obj.body2());
      }
    };

    eval_EBlock(obj) {
      var self = this, res, defenv, env1;
      res = null;
      defenv = Env.HashEnv.new(Enso.EMap.new(), self.D$.get$("env"));
      self.dynamic_bind(function() {
        return obj.fundefs().each(function(c) {
          return self.eval_M(c);
        });
      }, Enso.EMap.new({in_fc: false, env: defenv}));
      env1 = Env.HashEnv.new(Enso.EMap.new(), defenv);
      self.dynamic_bind(function() {
        return obj.body().each(function(c) {
          return res = self.eval_M(c);
        });
      }, Enso.EMap.new({in_fc: false, env: env1}));
      return res;
    };

    eval_EFunDef(obj) {
      var self = this, forms;
      forms = [];
      obj.formals().each(function(f) {
        return forms.push(f.name());
      });
      self.D$.get$("env") .set$(obj.name(), Impl.Closure.make_closure(obj.body(), forms, self.D$.get$("env"), self));
      return null;
    };

    eval_ELambda(obj) {
      var self = this, forms;
      forms = [];
      obj.formals().each(function(f) {
        return forms.push(f.name());
      });
      return function(...p) {
        return Impl.Closure.make_closure(obj.body(), forms, self.D$.get$("env"), self)(...p);
      };
    };

    eval_EFunCall(obj) {
      var self = this, m, b;
      m = self.dynamic_bind(function() {
        return self.eval_M(obj.fun());
      }, Enso.EMap.new({in_fc: true}));
      if (obj.lambda() == null) {
        return m(...obj.params().map(function(p) {
          return self.eval_M(p);
        }));
      } else {
        b = self.eval_M(obj.lambda());
        return m(b, ...obj.params().map(function(p) {
          return self.eval_M(p);
        }));
      }
    };

    eval_EAssign(obj) {
      var self = this;
      return self.lvalue(obj.var()).set_value(self.eval_M(obj.val()));
    }; }};

class EvalCommandC extends Enso.mix(Enso.EnsoBaseClass, EvalCommand) {
  static new(...args) { return new EvalCommandC(...args) };

  constructor() {
    super();
  };
};

Impl = {
  eval_M: eval_M,
  Closure: Closure,
  EvalCommand: EvalCommand,
  EvalCommandC: EvalCommandC,
};
module.exports = Impl ;
