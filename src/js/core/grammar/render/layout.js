define([
  "core/expr/code/eval",
  "core/expr/code/env",
  "core/schema/tools/print",
  "core/system/utils/paths",
  "core/system/library/schema"
],
function(Eval, Env, Print, Paths, Schema) {
  var Layout ;
  var RenderClass = MakeClass("RenderClass", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(slash_keywords) {
        var self = this; 
        if (slash_keywords === undefined) slash_keywords = true;
        self.$.depth = 0;
        self.$.stack = [];
        self.$.indent_amount = 2;
        self.$.slash_keywords = slash_keywords;
        self.$.create_stack = [];
        self.$.avoid_optimization = true;
        self.$.debug = false;
        return self.$.need_pop = 0;
      };

      this.render = function(grammar, obj) {
        var self = this; 
        var r;
        r = self.recurse(grammar, SingletonStream.new(obj));
        if (! r) {
          self.$.create_stack.each_with_index(function(p, i) {
            puts(S("*****", i + self.$.success >= self.$.create_stack.size()
              ? "SUCCESS"
              : "FAIL", "*****"));
            Print.Print.print(p._get(0), 2);
            puts("-----------------");
            return Print.Print.print(p._get(1), 2);
          });
          puts(S("grammar=", grammar, " obj=", obj, "\n\n"));
          self.raise("Can't render this object");
        }
        return r;
      };

      this.Grammar = function(this_V, stream, container) {
        var self = this; 
        self.$.root = stream.current();
        //self.$.literals = Scan.collect_keywords(this_V);
        return self.recurse(this_V.start().arg(), SingletonStream.new(stream.current()), container);
      };

      this.recurse = function(pat, data, container) {
        var self = this; 
        if (container === undefined) container = null;
        var pair, val;
        pair = S(pat, data.current());
        if (! self.$.stack.include_P(pair)) {
          self.$.stack.push(pair);
          if (self.$.debug) {
            puts(S(" ".repeat(self.$.depth), pat, " ", data.current()));
            self.$.depth = self.$.depth + 1;
          }
          val = self.send(pat.schema_class().name(), pat, data, container);
          if (self.$.debug) {
            self.$.depth = self.$.depth - 1;
            puts(S(" ".repeat(self.$.depth), pat, " ", data.current(), " ==> ", val));
          }
          self.$.stack.pop();
          return val;
        }
      };

      this.Call = function(this_V, stream, container) {
        var self = this; 
        return self.recurse(this_V.rule().arg(), stream, container);
      };

      this.Alt = function(this_V, stream, container) {
        var self = this; 
        var pred;
        if (self.$.avoid_optimization) {
          return this_V.alts().find_first(function(pat) {
            return self.recurse(pat, stream.copy(), container);
          });
        } else {
          if (! this_V.extra_instance_data()) {
            this_V.set_extra_instance_data([]);
            self.scan_alts(this_V, this_V.extra_instance_data());
          }
          return this_V.extra_instance_data().find_first(function(info) {
            pred = info._get(0);
            if (! pred || pred(stream.current(), self.$.localEnv)) {
              return self.recurse(info._get(1), stream.copy(), container);
            }
          });
        }
      };

      this.scan_alts = function(this_V, alts) {
        var self = this; 
        var pred;
        return this_V.alts().each(function(pat) {
          if (pat.Alt_P()) {
            return self.scan_alts(pat, self.infos());
          } else {
            pred = PredicateAnalysis.new().recurse(pat);
            return alts.push([pred, pat]);
          }
        });
      };

      this.Sequence = function(this_V, stream, container) {
        var self = this; 
        var items, item, ok;
        items = true;
        ok = this_V.elements().all_P(function(x) {
          item = self.recurse(x, stream, container);
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

      this.Create = function(this_V, stream, container) {
        var self = this; 
        var obj, res;
        obj = stream.current();
        if (! (obj == null) && obj.schema_class().name() == this_V.name()) {
          stream.next();
          self.$.create_stack.pop(self.$.need_pop);
          self.$.need_pop = self.$.success = 0;
          self.$.create_stack.push([this_V, obj]);
          res = self.recurse(this_V.arg(), SingletonStream.new(obj), obj);
          if (res) {
            self.$.success = self.$.success + 1;
          }
          self.$.need_pop = self.$.need_pop + 1;
          return res;
        } else {
          return null;
        }
      };

      this.Field = function(this_V, stream, container) {
        var self = this; 
        var obj, data, fld;
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
            var v = obj._get(this_V.name());
            if (v === undefined) v = null; // raise("RALLY BAD!" + obj + "." + this_V + "=" + obj[this_V.name()]);
            if (fld.many()) {
              data = ManyStream.new(v);
            } else {
              data = SingletonStream.new(v);
            }
          }
          return self.recurse(this_V.arg(), data, container);
        }
      };

      this.Value = function(this_V, stream, container) {
        var self = this; 
        var obj;
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
                  return self.output("\\" + obj);
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

      this.Ref = function(this_V, stream, container) {
        var self = this; 
        var obj, key_field;
        obj = stream.current();
        if (! (obj == null)) {
          key_field = Schema.class_key(obj.schema_class());
          return self.output(obj._get(key_field.name()));
        }
      };

      this.Lit = function(this_V, stream, container) {
        var self = this; 
        var obj;
        obj = stream.current();
        return self.output(this_V.value());
      };

      this.output = function(v) {
        var self = this; 
        return v;
      };

      this.Code = function(this_V, stream, container) {
        var self = this; 
        var obj, code, interp;
        obj = stream.current();
        if (this_V.schema_class().defined_fields().map(function(f) {
          return f.name();
        }).include_P("code") && this_V.code() != "") {
          code = this_V.code().gsub("=", "==").gsub(";", "&&").gsub("@", "self.");
          return obj.instance_eval(code);
        } else {
          interp = Eval.EvalExprC.new();
          return interp.dynamic_bind(function() {
            return interp.eval(this_V.expr());
          }, new EnsoHash ({ env: Env.ObjEnv.new(obj, self.$.localEnv) }));
        }
      };

      this.Regular = function(this_V, stream, container) {
        var self = this; 
        var oldEnv, s, i, ok, v, pos;
        if (! this_V.many()) {
          return self.recurse(this_V.arg(), stream, container) || true;
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
              v = self.recurse(this_V.sep(), stream, container);
              if (v) {
                s.push(v);
              } else {
                ok = false;
              }
            }
            if (ok) {
              pos = stream.size();
              v = self.recurse(this_V.arg(), stream, container);
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

      this.NoSpace = function(this_V, stream, container) {
        var self = this; 
        return this_V;
      };

      this.Indent = function(this_V, stream, container) {
        var self = this; 
        return this_V;
      };

      this.Break = function(this_V, stream, container) {
        var self = this; 
        return this_V;
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
        var pred;
        return this_V.elements().reduce(function(memo, x) {
          pred = self.recurse(x);
          if (memo && pred) {
            return self.lambda(function(obj, env) {
              return memo(obj, env) && pred(obj, env);
            });
          } else {
            return memo || pred;
          }
        }, null);
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
        if (data === undefined) raise("BAD!");
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
        var v = self.$.index < self.$.collection.size() && self.$.collection._get(self.$.index);
        if (v === undefined) raise("BAD!");
        return v;
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

  var DisplayFormat = MakeClass("DisplayFormat", null, [],
    function() {
      this.print = function(grammar, obj, output, slash_keywords) {
        var self = this; 
        if (output === undefined) output = System.stdout();
        if (slash_keywords === undefined) slash_keywords = true;
        var layout;
        layout = RenderClass.new(slash_keywords).render(grammar, obj);
        DisplayFormat.new(output).print(layout);
        return output.push("\n");
      };
    },
    function(super$) {
      this.initialize = function(out) {
        var self = this; 
        self.$.out = out;
        self.$.indent = 0;
        return self.$.lines = 0;
      };

      this.print = function(obj) {
        var self = this; 
        if (obj == true) {
        } else if (System.test_type(obj, Array)) {
          return obj.each(function(x) {
            return self.print(x);
          });
        } else if (System.test_type(obj, String)) {
          if (self.$.lines > 0) {
            self.$.out.push("\n".repeat(self.$.lines));
            self.$.out.push(" ".repeat(self.$.indent));
            self.$.lines = 0;
          } else if (self.$.space) {
            self.$.out.push(" ");
          }
          self.$.out.push(obj);
          return self.$.space = true;
        } else if (obj.NoSpace_P()) {
          return self.$.space = false;
        } else if (obj.Indent_P()) {
          return self.$.indent = self.$.indent + 2 * obj.indent();
        } else if (obj.Break_P()) {
          return self.$.lines = System.max(self.$.lines, obj.lines());
        } else {
          return self.raise(S("Unknown format ", obj));
        }
      };
    });

  Layout = {
    RenderClass: RenderClass,
    PredicateAnalysis: PredicateAnalysis,
    SingletonStream: SingletonStream,
    ManyStream: ManyStream,
    DisplayFormat: DisplayFormat,

  };
  return Layout;
})
