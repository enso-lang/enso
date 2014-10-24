define([
  "core/expr/code/eval",
  "core/expr/code/env",
  "core/schema/tools/print",
  "core/schema/code/factory",
  "core/system/utils/paths",
  "core/system/library/schema",
  "core/semantics/code/interpreter"
],
function(Eval, Env, Print, Factory, Paths, Schema, Interpreter) {
  var Layout ;
  var RenderGrammar = MakeMixin([Interpreter.Dispatcher], function() {
    this.init = function() {
      var self = this; 
      return self.super();
    };

    this.render = function(pat) {
      var self = this; 
      var stream, pair, val;
      stream = self.$.D._get("stream");
      self.$.stack = self.$.stack || [];
      pair = S(pat.to_s(), "/", stream.current());
      if (! self.$.stack.include_P(pair)) {
        self.$.stack.push(pair);
        if (self.$.indent) {
          puts(" " * self.$.indent + pat);
          self.$.indent = self.$.indent + 1;
        }
        val = self.dispatch_obj("render", pat);
        if (self.$.indent) {
          self.$.indent = self.$.indent - 1;
        }
        self.$.stack.pop();
        return val;
      }
    };

    this.render_Grammar = function(this_V) {
      var self = this; 
      var stream, out, format;
      stream = self.$.D._get("stream");
      self.$.stack = [];
      self.$.create_stack = [];
      self.$.need_pop = 0;
      self.$.root = stream.current();
      if (self.$.slash_keywords) {
        self.$.literals = Scan.collect_keywords(this_V);
      }
      self.$.modelmap = new EnsoHash ({ });
      out = self.render(this_V.start().arg());
      format = new EnsoHash ({ });
      format._set("lines", 0);
      format._set("space", false);
      format._set("indent", 0);
      return self.combine(out, format);
    };

    this.render_Call = function(this_V) {
      var self = this; 
      return self.render(this_V.rule().arg());
    };

    this.render_Alt = function(this_V) {
      var self = this; 
      var stream, pred;
      stream = self.$.D._get("stream");
      if (self.$.avoid_optimization) {
        return this_V.alts().find_first(function(pat) {
          return self.dynamic_bind(function() {
            return self.render(pat);
          }, new EnsoHash ({ stream: stream.copy() }));
        });
      } else {
        if (! this_V.extra_instance_data()) {
          this_V.set_extra_instance_data([]);
          self.scan_alts(this_V, this_V.extra_instance_data());
        }
        return this_V.extra_instance_data().find_first(function(info) {
          pred = info._get(0);
          if (! pred || pred(stream.current(), self.$.localEnv)) {
            return self.dynamic_bind(function() {
              return self.render(info._get(1));
            }, new EnsoHash ({ stream: stream.copy() }));
          }
        });
      }
    };

    this.render_Sequence = function(this_V) {
      var self = this; 
      var items, item, ok;
      items = true;
      ok = this_V.elements().all_P(function(x) {
        item = self.render(x);
        if (item) {
          if (item == true) {
            return true;
          } else if (System.test_type(items, Array)) {
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

    this.render_Create = function(this_V) {
      var self = this; 
      var stream, obj, res, format;
      stream = self.$.D._get("stream");
      obj = stream.current();
      if (! (obj == null) && obj.schema_class().name() == this_V.name()) {
        stream.next();
        self.$.create_stack.pop(self.$.need_pop);
        self.$.need_pop = self.$.success = 0;
        self.$.create_stack.push([this_V, obj]);
        res = self.dynamic_bind(function() {
          return self.render(this_V.arg());
        }, new EnsoHash ({ stream: SingletonStream.new(obj) }));
        if (res) {
          self.$.success = self.$.success + 1;
        }
        self.$.need_pop = self.$.need_pop + 1;
        if (self.$.add_tags && res != null) {
          format = new EnsoHash ({ });
          format._set("lines", 0);
          format._set("space", false);
          format._set("indent", 0);
          res = (S("*[*debug id='", obj.schema_class().name(), obj._id(), "'*]*") + self.combine(res, format)) + "*[*/debug*]*";
        }
        self.$.modelmap._set(res, obj);
        return res;
      } else {
        return null;
      }
    };

    this.render_Field = function(this_V) {
      var self = this; 
      var stream, obj, data, fld, res, format;
      stream = self.$.D._get("stream");
      obj = stream.current();
      if (this_V.arg().Lit_P()) {
        if (this_V.arg().value() == obj._get(this_V.name())) {
          return this_V.arg().value();
        }
      } else {
        if (this_V.name() == "_id") {
          data = SingletonStream.new(obj._id());
        } else {
          fld = obj.schema_class().all_fields()._get(this_V.name());
          if (! fld) {
            self.raise(S("Unknown field ", obj.schema_class().name(), ".", this_V.name()));
          }
          if (fld.many()) {
            data = ManyStream.new(obj._get(this_V.name()));
          } else {
            data = SingletonStream.new(obj._get(this_V.name()));
          }
        }
        res = self.dynamic_bind(function() {
          return self.render(this_V.arg());
        }, new EnsoHash ({ stream: data }));
        if (self.$.add_tags && res != null) {
          format = new EnsoHash ({ });
          format._set("lines", 0);
          format._set("space", false);
          format._set("indent", 0);
          res = (S("*[*debug id='", obj.schema_class().name(), obj._id(), this_V.name(), "'*]*") + self.combine(res, format)) + "*[*/debug*]*";
        }
        return res;
      }
    };

    this.render_Value = function(this_V) {
      var self = this; 
      var stream, obj;
      stream = self.$.D._get("stream");
      obj = stream.current();
      if (! (obj == null)) {
        if (! ((System.test_type(obj, String) || System.test_type(obj, Fixnum)) || System.test_type(obj, Float))) {
          self.raise(S("Data is not literal ", obj));
        }
        switch (this_V.kind()) {
          case "str":
            if (System.test_type(obj, String)) {
              return self.output(obj.inspect());
            }
          case "sym":
            if (System.test_type(obj, String)) {
              if (self.$.slash_keywords && self.$.literals.include_P(obj)) {
                return self.output("\\\\" + obj);
              } else {
                return self.output(obj);
              }
            }
          case "int":
            if (System.test_type(obj, Fixnum)) {
              return self.output(obj.to_s());
            }
          case "real":
            if (System.test_type(obj, Float)) {
              return self.output(obj.to_s());
            }
          case "atom":
            if (System.test_type(obj, String)) {
              return self.output(obj.inspect());
            } else {
              return self.output(obj.to_s());
            }
          default:
            return self.raise(S("Unknown type ", this_V.kind()));
        }
      }
    };

    this.render_Ref = function(this_V) {
      var self = this; 
      var stream, obj, key_field;
      stream = self.$.D._get("stream");
      obj = stream.current();
      if (! (obj == null)) {
        key_field = obj.schema_class().key();
        return self.output(obj._get(key_field.name()));
      }
    };

    this.render_Lit = function(this_V) {
      var self = this; 
      var stream, obj;
      stream = self.$.D._get("stream");
      obj = stream.current();
      return self.output(this_V.value());
    };

    this.render_Code = function(this_V) {
      var self = this; 
      var stream, obj, rhs, lhs;
      stream = self.$.D._get("stream");
      obj = stream.current();
      if (this_V.expr().EBinOp_P() && this_V.expr().op() == "eql?") {
        rhs = Eval.eval(this_V.expr().e2(), new EnsoHash ({ env: Env.ObjEnv.new(obj, self.$.localEnv) }));
        if (System.test_type(rhs, Factory.MObject)) {
          lhs = Eval.eval(this_V.expr().e1(), new EnsoHash ({ env: Env.ObjEnv.new(obj, self.$.localEnv) }));
          return lhs.schema_class() == rhs.schema_class();
        } else {
          return Eval.eval(this_V.expr(), new EnsoHash ({ env: Env.ObjEnv.new(obj, self.$.localEnv) }));
        }
      } else {
        return Eval.eval(this_V.expr(), new EnsoHash ({ env: Env.ObjEnv.new(obj, self.$.localEnv) }));
      }
    };

    this.render_Regular = function(this_V) {
      var self = this; 
      var stream, oldEnv, s, i, ok, v, pos;
      stream = self.$.D._get("stream");
      if (! this_V.many()) {
        return self.render(this_V.arg()) || true;
      } else if (stream.size() > 0 || this_V.optional()) {
        oldEnv = self.$.localEnv;
        self.$.localEnv = Env.HashEnv.new();
        self.$.localEnv._set("_size", stream.size());
        s = [];
        i = 0;
        ok = true;
        while (ok && stream.size() > 0) {
          self.$.localEnv._set("_index", i);
          self.$.localEnv._set("_first", i == 0);
          self.$.localEnv._set("_last", stream.size() == 1);
          if (i > 0 && this_V.sep()) {
            v = self.render(this_V.sep());
            if (v) {
              s.push(v);
            } else {
              ok = false;
            }
          }
          if (ok) {
            pos = stream.size();
            v = self.render(this_V.arg());
            if (v) {
              s.push(v);
              if (stream.size() == pos) {
                stream.next();
              }
              i = i + 1;
            } else {
              ok = false;
            }
          }
        }
        self.$.localEnv = oldEnv;
        if (ok && stream.size() == 0) {
          return s;
        }
      }
    };

    this.render_NoSpace = function(this_V) {
      var self = this; 
      return this_V;
    };

    this.render_Indent = function(this_V) {
      var self = this; 
      return this_V;
    };

    this.render_Break = function(this_V) {
      var self = this; 
      return this_V;
    };

    this.output = function(v) {
      var self = this; 
      return v;
    };

    this.scan_alts = function(this_V, alts) {
      var self = this; 
      var pred;
      return this_V.alts().each(function(pat) {
        if (pat.Alt_P()) {
          return self.scan_alts(pat, self.infos());
        } else {
          pred = PredicateAnalysis.new().recurse(pat);
          puts(S("pred = ", pred));
          return alts.push([pred, pat]);
        }
      });
    };

    this.combine = function(obj, format) {
      var self = this; 
      var res;
      if (obj == true) {
        return "";
      } else if (System.test_type(obj, Array)) {
        res = "";
        obj.each(function(x) {
          return res = res + self.combine(x, format);
        });
        return res;
      } else if (System.test_type(obj, String)) {
        res = "";
        if (format._get("lines") > 0) {
          res = res + "\n".repeat(format._get("lines"));
          res = res + " ".repeat(format._get("indent"));
          format._set("lines", 0);
        } else if (format._get("space")) {
          res = res + " ";
        }
        res = res + obj;
        format._set("space", true);
        return res;
      } else if (obj.NoSpace_P()) {
        format._set("space", false);
        return "";
      } else if (obj.Indent_P()) {
        format._set("indent", format._get("indent") + 2 * obj.indent());
        return "";
      } else if (obj.Break_P()) {
        format._set("lines", System.max(format._get("lines"), obj.lines()));
        return "";
      } else {
        return self.raise(S("Unknown format ", obj));
      }
    };
  });

  var PredicateAnalysis = MakeClass("PredicateAnalysis", null, [],
    function() {
    },
    function(super$) {
      this.recurse = function(pat) {
        var self = this; 
        return self.send(pat.schema_class().name(), pat);
      };

      this.Call = function(this_V) {
        var self = this; 
        return self.recurse(this_V.rule().arg());
      };

      this.Alt = function(this_V) {
        var self = this; 
        var fields, name, symbols;
        if (this_V.alts().all_P(function(alt) {
          return alt.Field_P() && alt.arg().Lit_P();
        })) {
          fields = this_V.alts().map(function(alt) {
            return alt.name();
          });
          name = fields._get(0);
          if (fields.all_P(function(x) {
            return x == name;
          })) {
            symbols = this_V.alts().map(function(alt) {
              return alt.arg().value();
            });
            return self.lambda(function(obj, env) {
              return symbols.include_P(obj._get(name));
            });
          }
        }
      };

      this.Sequence = function(this_V) {
        var self = this; 
        var memo, pred;
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

      this.Create = function(this_V) {
        var self = this; 
        var name, pred;
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

      this.Field = function(this_V) {
        var self = this; 
        var name, value, pred;
        name = this_V.name();
        if (this_V.arg().Lit_P()) {
          value = this_V.arg().value();
          return self.lambda(function(obj, env) {
            return value == obj._get(name);
          });
        } else if (this_V.name() != "_id") {
          pred = self.recurse(this_V.arg());
          if (pred) {
            return self.lambda(function(obj, env) {
              return pred(obj._get(name), env);
            });
          }
        }
      };

      this.Value = function(this_V) {
        var self = this; 
      };

      this.Ref = function(this_V) {
        var self = this; 
        return self.lambda(function(obj, env) {
          return ! (obj == null);
        });
      };

      this.Lit = function(this_V) {
        var self = this; 
      };

      this.Code = function(this_V) {
        var self = this; 
        var code, interp;
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
              return interp.eval(this_V.expr());
            }, new EnsoHash ({ env: Env.ObjEnv.new(obj, env) }));
          });
        }
      };

      this.Regular = function(this_V) {
        var self = this; 
        if (this_V.many() && ! this_V.optional()) {
          return self.lambda(function(obj, env) {
            return obj.size() > 0;
          });
        }
      };

      this.NoSpace = function(this_V) {
        var self = this; 
      };

      this.Indent = function(this_V) {
        var self = this; 
      };

      this.Break = function(this_V) {
        var self = this; 
      };
    });

  var SingletonStream = MakeClass("SingletonStream", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(data, used) {
        var self = this; 
        if (used === undefined) used = false;
        self.$.data = data;
        return self.$.used = used;
      };

      this.size = function() {
        var self = this; 
        if (self.$.used) {
          return 0;
        } else {
          return 1;
        }
      };

      this.current = function() {
        var self = this; 
        if (self.$.used) {
          return null;
        } else {
          return self.$.data;
        }
      };

      this.next = function() {
        var self = this; 
        return self.$.used = true;
      };

      this.copy = function() {
        var self = this; 
        return SingletonStream.new(self.$.data, self.$.used);
      };
    });

  var ManyStream = MakeClass("ManyStream", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(collection, index) {
        var self = this; 
        if (index === undefined) index = 0;
        self.$.collection = System.test_type(collection, Array)
          ? collection
          : collection.values();
        self.$.index = index;
        if (self.$.collection.include_P(false)) {
          return self.raise("not an object!!");
        }
      };

      this.size = function() {
        var self = this; 
        return self.$.collection.size() - self.$.index;
      };

      this.current = function() {
        var self = this; 
        return self.$.index < self.$.collection.size() && self.$.collection._get(self.$.index);
      };

      this.next = function() {
        var self = this; 
        return self.$.index = self.$.index + 1;
      };

      this.copy = function() {
        var self = this; 
        return ManyStream.new(self.$.collection, self.$.index);
      };
    });

  var DisplayFormat = MakeClass("DisplayFormat", null, [RenderGrammar],
    function() {
      this.print = function() {
        var self = this; 
        var args = compute_rest_arguments(arguments, 0);
        return Layout.DisplayFormat.new().print.apply(Layout.DisplayFormat.new(), [].concat(args));
      };
    },
    function(super$) {
      this.print = function(grammar, obj, output, slash_keywords, add_tags) {
        var self = this; 
        if (output === undefined) output = System.stdout();
        if (slash_keywords === undefined) slash_keywords = true;
        if (add_tags === undefined) add_tags = false;
        var res;
        self.$.slash_keywords = slash_keywords;
        self.$.avoid_optimization = true;
        self.$.out = output;
        self.$.add_tags = add_tags;
        res = self.dynamic_bind(function() {
          return self.render(grammar);
        }, new EnsoHash ({ stream: SingletonStream.new(obj) }));
        output.push(res);
        output.push("\n");
        return res;
      };
    });

  Layout = {
    RenderGrammar: RenderGrammar,
    PredicateAnalysis: PredicateAnalysis,
    SingletonStream: SingletonStream,
    ManyStream: ManyStream,
    DisplayFormat: DisplayFormat,

  };
  return Layout;
})
