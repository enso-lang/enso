'use strict'

//// Layout ////

var cwd = process.cwd() + '/';
var Eval = require(cwd + "core/expr/code/eval.js");
var Env = require(cwd + "core/expr/code/env.js");
var Print = require(cwd + "core/schema/tools/print.js");
var Factory = require(cwd + "core/schema/code/factory.js");
var Schema = require(cwd + "core/system/library/schema.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Enso = require(cwd + "enso.js");

var Layout;

function RenderGrammar(parent) {
  return class extends Enso.mix(parent, Interpreter.Dispatcher) {
    render(pat) {
      var self = this, stream, pair, val;
      stream = self.D$.get$("stream");
      self.stack$ = self.stack$ || [];
      pair = Enso.S(pat.to_s(), "/", stream.current());
      if (! self.stack$.include_P(pair)) {
        self.stack$.push(pair);
        if (self.indent$) {
          puts(" " * self.indent$ + pat);
          self.indent$ = self.indent$ + 1;
        }
        val = self.dispatch_obj("render", pat);
        if (self.indent$) {
          self.indent$ = self.indent$ - 1;
        }
        self.stack$.pop();
        return val;
      }
    };

    render_Grammar(this_V) {
      var self = this, stream, out, format;
      stream = self.D$.get$("stream");
      self.stack$ = [];
      self.create_stack$ = [];
      self.need_pop$ = 0;
      self.root$ = stream.current();
      if (self.slash_keywords$) {
        self.literals$ = Scan.collect_keywords(this_V);
      }
      self.modelmap$ = Enso.EMap.new();
      out = self.render(this_V.start().arg());
      format = Enso.EMap.new();
      format .set$("lines", 0);
      format .set$("space", false);
      format .set$("indent", 0);
      return self.combine(out, format);
    };

    render_Call(this_V) {
      var self = this;
      return self.render(this_V.rule().arg());
    };

    render_Alt(this_V) {
      var self = this, stream, pred;
      stream = self.D$.get$("stream");
      if (self.avoid_optimization$) {
        return this_V.alts().find_first(function(pat) {
          return self.dynamic_bind(function() {
            return self.render(pat);
          }, Enso.EMap.new({stream: stream.copy()}));
        });
      } else {
        if (! this_V.extra_instance_data()) {
          this_V.set_extra_instance_data([]);
          self.scan_alts(this_V, this_V.extra_instance_data());
        }
        return this_V.extra_instance_data().find_first(function(info) {
          pred = info.get$(0);
          if (! pred || pred(stream.current(), self.localEnv$)) {
            return self.dynamic_bind(function() {
              return self.render(info.get$(1));
            }, Enso.EMap.new({stream: stream.copy()}));
          }
        });
      }
    };

    render_Sequence(this_V) {
      var self = this, items, item, ok;
      items = true;
      ok = this_V.elements().all_P(function(x) {
        item = self.render(x);
        if (item) {
          if (item == true) {
            return true;
          } else if (Enso.System.test_type(items, Array)) {
            return items.push(item);
          } else if (items != true) {
            return items = [items, item];
          } else {
            return items = item;
          }
        }
      });
      if (ok) {
        return items;
      }
    };

    render_Create(this_V) {
      var self = this, stream, obj, res, format;
      stream = self.D$.get$("stream");
      obj = stream.current();
      if (! (obj == null) && obj.schema_class().name() == this_V.name()) {
        stream.next();
        self.create_stack$.pop(self.need_pop$);
        self.need_pop$ = self.success$ = 0;
        self.create_stack$.push([this_V, obj]);
        res = self.dynamic_bind(function() {
          return self.render(this_V.arg());
        }, Enso.EMap.new({stream: SingletonStream.new(obj)}));
        if (res) {
          self.success$ = self.success$ + 1;
        }
        self.need_pop$ = self.need_pop$ + 1;
        if (self.add_tags$ && res != null) {
          format = Enso.EMap.new();
          format .set$("lines", 0);
          format .set$("space", false);
          format .set$("indent", 0);
          res = (Enso.S("*[*debug id='", obj.schema_class().name(), obj.identity(), "'*]*") + self.combine(res, format)) + "*[*/debug*]*";
        }
        self.modelmap$ .set$(res, obj);
        return res;
      } else {
        return null;
      }
    };

    render_Field(this_V) {
      var self = this, stream, obj, data, fld, res, format;
      stream = self.D$.get$("stream");
      obj = stream.current();
      if (Enso.System.test_type(this_V.arg(), "Lit")) {
        if (this_V.arg().value() == obj.get$(this_V.name())) {
          return this_V.arg().value();
        }
      } else {
        if (this_V.name() == "identity") {
          data = SingletonStream.new(obj.identity());
        } else {
          fld = obj.schema_class().all_fields().get$(this_V.name());
          if (! fld) {
            self.raise(Enso.S("Unknown field ", obj.schema_class().name(), ".", this_V.name()));
          }
          if (fld.many()) {
            data = ManyStream.new(obj.get$(this_V.name()));
          } else {
            data = SingletonStream.new(obj.get$(this_V.name()));
          }
        }
        res = self.dynamic_bind(function() {
          return self.render(this_V.arg());
        }, Enso.EMap.new({stream: data}));
        if (self.add_tags$ && res != null) {
          format = Enso.EMap.new();
          format .set$("lines", 0);
          format .set$("space", false);
          format .set$("indent", 0);
          res = (Enso.S("*[*debug id='", obj.schema_class().name(), obj.identity(), this_V.name(), "'*]*") + self.combine(res, format)) + "*[*/debug*]*";
        }
        return res;
      }
    };

    render_Value(this_V) {
      var self = this, stream, obj;
      stream = self.D$.get$("stream");
      obj = stream.current();
      if (! (obj == null)) {
        if (! ((Enso.System.test_type(obj, String) || Enso.System.test_type(obj, Enso.Numeric)) || Enso.System.test_type(obj, Float))) {
          self.raise(Enso.S("Data is not literal ", obj));
        }
        switch (this_V.kind()) {
          case "str":
            if (Enso.System.test_type(obj, String)) {
              return self.output(("\"" + obj) + "\"");
            }
          case "sym":
            if (Enso.System.test_type(obj, String)) {
              if (self.slash_keywords$ && self.literals$.include_P(obj)) {
                return self.output("\\" + obj);
              } else {
                return self.output(obj);
              }
            } else {
              return self.raise(Enso.S("Symbol is not a strign ", obj));
            }
          case "int":
            if (Enso.System.test_type(obj, Enso.Numeric)) {
              return self.output(obj.to_s());
            }
          case "real":
            if (Enso.System.test_type(obj, Float)) {
              return self.output(obj.to_s());
            }
          case "atom":
            if (Enso.System.test_type(obj, String)) {
              return self.output(("\"" + obj) + "\"");
            } else {
              return self.output(obj.to_s());
            }
          default:
            return self.raise(Enso.S("Unknown type ", this_V.kind()));
        }
      }
    };

    render_Ref(this_V) {
      var self = this, stream, obj, key_field;
      stream = self.D$.get$("stream");
      obj = stream.current();
      if (! (obj == null)) {
        key_field = obj.schema_class().key();
        return self.output(obj.get$(key_field.name()));
      }
    };

    render_Lit(this_V) {
      var self = this, stream, obj;
      stream = self.D$.get$("stream");
      obj = stream.current();
      return self.output(this_V.value());
    };

    render_Code(this_V) {
      var self = this, stream, obj, rhs, lhs;
      stream = self.D$.get$("stream");
      obj = stream.current();
      if (Enso.System.test_type(this_V.expr(), "EBinOp") && this_V.expr().op() == "eql?") {
        rhs = Eval.eval_M(this_V.expr().e2(), Enso.EMap.new({env: Env.ObjEnv.new(obj, self.localEnv$)}));
        if (Enso.System.test_type(rhs, Factory.MObject)) {
          lhs = Eval.eval_M(this_V.expr().e1(), Enso.EMap.new({env: Env.ObjEnv.new(obj, self.localEnv$)}));
          return lhs.schema_class() == rhs.schema_class();
        } else {
          return Eval.eval_M(this_V.expr(), Enso.EMap.new({env: Env.ObjEnv.new(obj, self.localEnv$)}));
        }
      } else {
        return Eval.eval_M(this_V.expr(), Enso.EMap.new({env: Env.ObjEnv.new(obj, self.localEnv$)}));
      }
    };

    render_Regular(this_V) {
      var self = this, stream, oldEnv, s, i, ok, v, pos;
      stream = self.D$.get$("stream");
      if (! this_V.many()) {
        return self.render(this_V.arg()) || true;
      } else if (stream.size_M() > 0 || this_V.optional()) {
        oldEnv = self.localEnv$;
        self.localEnv$ = Env.HashEnv.new();
        s = [];
        i = 0;
        ok = true;
        while (ok && stream.size_M() > 0) {
          self.localEnv$ .set$("_index", i);
          self.localEnv$ .set$("_first", i == 0);
          self.localEnv$ .set$("_last", stream.size_M() == 1);
          if (i > 0 && this_V.sep()) {
            v = self.render(this_V.sep());
            if (v) {
              s.push(v);
            } else {
              ok = false;
            }
          }
          if (ok) {
            pos = stream.size_M();
            v = self.render(this_V.arg());
            if (v) {
              s.push(v);
              if (stream.size_M() == pos) {
                stream.next();
              }
              i = i + 1;
            } else {
              ok = false;
            }
          }
        }
        self.localEnv$ = oldEnv;
        if (ok && stream.size_M() == 0) {
          return s;
        }
      }
    };

    render_NoSpace(this_V) {
      var self = this;
      return this_V;
    };

    render_Indent(this_V) {
      var self = this;
      return this_V;
    };

    render_Break(this_V) {
      var self = this;
      return this_V;
    };

    output(v) {
      var self = this;
      return v;
    };

    scan_alts(this_V, alts) {
      var self = this, pred;
      return this_V.alts().each(function(pat) {
        if (Enso.System.test_type(pat, "Alt")) {
          return self.scan_alts(pat, self.infos());
        } else {
          pred = PredicateAnalysis.new().recurse(pat);
          puts(Enso.S("pred = ", pred));
          return alts.push([pred, pat]);
        }
      });
    };

    combine(obj, format) {
      var self = this, res;
      if (obj == true) {
        return "";
      } else if (obj == null) {
        return self.raise("GRAMMAR FAILED TO PRODUCE OUTPUT");
      } else if (Enso.System.test_type(obj, Array)) {
        res = "";
        obj.each(function(x) {
          return res = res + self.combine(x, format);
        });
        return res;
      } else if (Enso.System.test_type(obj, String)) {
        res = "";
        if (format.get$("lines") > 0) {
          res = res + "\n".repeat(format.get$("lines"));
          res = res + " ".repeat(format.get$("indent"));
          format .set$("lines", 0);
        } else if (format.get$("space")) {
          res = res + " ";
        }
        res = res + obj;
        format .set$("space", true);
        return res;
      } else {
        switch (obj.schema_class().name()) {
          case "NoSpace":
            format .set$("space", false);
            return "";
          case "Indent":
            format .set$("indent", format.get$("indent") + 2 * obj.indent());
            return "";
          case "Break":
            format .set$("lines", Enso.System.max(format.get$("lines"), obj.lines()));
            return "";
          default:
            return self.raise(Enso.S("Unknown format ", obj));
        }
      }
    }; }};

class PredicateAnalysis {
  static new(...args) { return new PredicateAnalysis(...args) };

  recurse(pat) {
    var self = this;
    return self.send(pat.schema_class().name(), pat);
  };

  Call(this_V) {
    var self = this;
    return self.recurse(this_V.rule().arg());
  };

  Alt(this_V) {
    var self = this, fields, name, symbols;
    if (this_V.alts().all_P(function(alt) {
      return Enso.System.test_type(alt, "Field") && Enso.System.test_type(alt.arg(), "Lit");
    })) {
      fields = this_V.alts().map(function(alt) {
        return alt.name();
      });
      name = fields.get$(0);
      if (fields.all_P(function(x) {
        return x == name;
      })) {
        symbols = this_V.alts().map(function(alt) {
          return alt.arg().value();
        });
        return self.lambda(function(obj, env) {
          return symbols.include_P(obj.get$(name));
        });
      }
    }
  };

  Sequence(this_V) {
    var self = this, memo, pred;
    memo = null;
    this_V.elements().each(function(x) {
      pred = self.recurse(x);
      if (memo && pred) {
        return self.lambda(function(obj, env) {
          return memo(obj, env) && pred(obj, env);
        });
      } else {
        return memo = memo || pred;
      }
    });
    return memo;
  };

  Create(this_V) {
    var self = this, name, pred;
    name = this_V.name();
    pred = self.recurse(this_V.arg());
    if (pred) {
      return self.lambda(function(obj, env) {
        return (! (obj == null) && obj.schema_class().name() == name) && pred(obj, env);
      });
    } else {
      return self.lambda(function(obj, env) {
        return ! (obj == null) && obj.schema_class().name() == name;
      });
    }
  };

  Field(this_V) {
    var self = this, name, value, pred;
    name = this_V.name();
    if (Enso.System.test_type(this_V.arg(), "Lit")) {
      value = this_V.arg().value();
      return self.lambda(function(obj, env) {
        return value == obj.get$(name);
      });
    } else if (this_V.name() != "identity") {
      pred = self.recurse(this_V.arg());
      if (pred) {
        return self.lambda(function(obj, env) {
          return pred(obj.get$(name), env);
        });
      }
    }
  };

  Value(this_V) {
    var self = this;
  };

  Ref(this_V) {
    var self = this;
    return self.lambda(function(obj, env) {
      return ! (obj == null);
    });
  };

  Lit(this_V) {
    var self = this;
  };

  Code(this_V) {
    var self = this, code, interp;
    if (this_V.schema_class().defined_fields().map(function(f) {
      return f.name();
    }).include_P("code") && this_V.code() != "") {
      code = this_V.code().gsub("=", "==").gsub(";", "&&").gsub("@", "self.");
      return self.lambda(function(obj, env) {
        return obj.instance_eval(code);
      });
    } else {
      interp = Eval.EvalExprC.new();
      return self.lambda(function(obj, env) {
        return interp.dynamic_bind(function() {
          return interp.eval_M(this_V.expr());
        }, Enso.EMap.new({env: Env.ObjEnv.new(obj, env)}));
      });
    }
  };

  Regular(this_V) {
    var self = this;
    if (this_V.many() && ! this_V.optional()) {
      return self.lambda(function(obj, env) {
        return obj.size_M() > 0;
      });
    }
  };

  NoSpace(this_V) {
    var self = this;
  };

  Indent(this_V) {
    var self = this;
  };

  Break(this_V) {
    var self = this;
  };
};

class SingletonStream {
  static new(...args) { return new SingletonStream(...args) };

  constructor(data, used = false) {
    var self = this;
    self.data$ = data;
    self.used$ = used;
  };

  size_M() {
    var self = this;
    if (self.used$) {
      return 0;
    } else {
      return 1;
    }
  };

  current() {
    var self = this;
    if (self.used$) {
      return null;
    } else {
      return self.data$;
    }
  };

  next() {
    var self = this;
    return self.used$ = true;
  };

  copy() {
    var self = this;
    return SingletonStream.new(self.data$, self.used$);
  };
};

class ManyStream {
  static new(...args) { return new ManyStream(...args) };

  constructor(collection, index = 0) {
    var self = this;
    self.collection$ = Enso.System.test_type(collection, Array)
      ? collection
      : collection.values();
    self.index$ = index;
    if (self.collection$.include_P(false)) {
      self.raise("not an object!!");
    }
  };

  size_M() {
    var self = this;
    return self.collection$.size_M() - self.index$;
  };

  current() {
    var self = this;
    if (self.index$ < self.collection$.size_M()) {
      return self.collection$.get$(self.index$);
    } else {
      return null;
    }
  };

  next() {
    var self = this;
    return self.index$ = self.index$ + 1;
  };

  copy() {
    var self = this;
    return ManyStream.new(self.collection$, self.index$);
  };
};

class DisplayFormat extends Enso.mix(Enso.EnsoBaseClass, RenderGrammar) {
  static new(...args) { return new DisplayFormat(...args) };

  static print(grammar, obj, output = Enso.System.stdout(), slash_keywords = true, add_tags = false) {
    var self = this;
    return Layout.DisplayFormat.new().print(grammar, obj, output, slash_keywords, add_tags);
  };

  print(grammar, obj, output, slash_keywords, add_tags) {
    var self = this, res;
    self.slash_keywords$ = slash_keywords;
    self.avoid_optimization$ = true;
    self.out$ = output;
    self.add_tags$ = add_tags;
    res = self.dynamic_bind(function() {
      return self.render(grammar);
    }, Enso.EMap.new({stream: SingletonStream.new(obj)}));
    output.write(res);
    output.write("\n");
    return res;
  };
};

Layout = {
  RenderGrammar: RenderGrammar,
  PredicateAnalysis: PredicateAnalysis,
  SingletonStream: SingletonStream,
  ManyStream: ManyStream,
  DisplayFormat: DisplayFormat,
};
module.exports = Layout ;
