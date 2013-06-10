define([
  "core/expr/code/env",
  "core/expr/code/eval",
  "core/schema/code/factory",
  "core/system/load/load"
],
function(Env, Eval, Factory, Load) {
  var Proxy ;
  var Proxy = MakeClass("Proxy", null, [],
    function() {
      this.$.factory = null;

      this.new = function() {
        var self = this; 
        var args = compute_rest_arguments(arguments, 0);
        if (System.test_type(args._get(0), TrueClass) || System.test_type(args._get(0), FalseClass)) {
          return args._get(0);
        } else {
          return super$.new.call(self);
        }
      };
    },
    function(super$) {
      this._val = function() { return this.$._val };

      this._sources = function() { return this.$._sources };
      this.set__sources = function(val) { this.$._sources  = val };

      this._tree = function() { return this.$._tree };
      this.set__tree = function(val) { this.$._tree  = val };

      this.initialize = function(val, file, path) {
        var self = this; 
        if (file === undefined) file = null;
        if (path === undefined) path = null;
        var id;
        if (self._class_.$.factory == null) {
          self._class_.$.factory = Factory.SchemaFactory.new(Load.load("expr.schema"));
        }
        if (System.test_type(val, Proxy)) {
          self.$._val = val._val();
          self.$._sources = val._sources();
          return self.$._tree = val._tree();
        } else {
          self.$._val = val;
          if ((file == null) != path == null) {
            self.raise("Improper init of proxy sources");
          }
          if (file == null) {
            self.$._sources = new EnsoHash ({ });
            return self.$._tree = Eval.make_const(self._class_.$.factory, val);
          } else {
            id = [file, path.to_s()].hash() % 100000;
            self.$._tree = self._class_.$.factory.EVar();
            self.$._tree.set_name(S("@", id));
            return self.$._sources = new EnsoHash ({ name: [file, path] });
          }
        }
      };

      this.ops = function() {
        var self = this; 
        return ["==", "+", "-", "*", "/", ">", "<", ">=", "<=", "-@"];
      };

      this.op2str = function(op) {
        var self = this; 
        if (op == "==") {
          return "eql?";
        } else {
          return op.to_s();
        }
      };

      this.method_missing = function(block, sym) {
        var self = this; 
        var args = compute_rest_arguments(arguments, 2);
        var f, newlist, res, other;
        if (System.test_type(self.$._val, Factory.MObject)) {
          if (f = self.$._val.schema_class().all_fields()._get(sym.to_s())) {
            if (! f.many()) {
              return Proxy.new(self.$._val.send(sym), self.$._val.factory().file_path()._get(0), self.$._val._path().field(sym.to_s()));
            } else if (f.type().key()) {
              newlist = new EnsoHash ({ });
              self.$._val._get(f.name()).each_pair(function(k, v) {
                return newlist._set(k, Proxy.new(v));
              });
              return newlist;
            } else {
              newlist = [];
              self.$._val._get(f.name()).each(function(v) {
                return newlist.push(Proxy.new(v));
              });
              return newlist;
            }
          } else {
            return self.$._val.send.apply(self.$._val, [block, sym].concat(args));
          }
        } else if (sym == "coerce") {
          return [Proxy.new(args._get(0)), self];
        } else if (self.ops().include_P(sym)) {
          res = null;
          if (args.empty_P()) {
            res = Proxy.new(self.$._val.send.apply(self.$._val, [block, sym].concat(args)));
            if (System.test_type(res, Proxy)) {
              res.set__sources(self.$._sources);
              res.set__tree(self._class_.$.factory.EUnOp(self.op2str(sym), self.$._tree));
            }
          } else {
            other = Proxy.new(args._get(0));
            res = Proxy.new(self.$._val.send(block, sym, other._val()));
            if (System.test_type(res, Proxy)) {
              if (System.test_type(other, Proxy)) {
                res.set__sources(self.$._sources.merge(other._sources()));
                res.set__tree(self._class_.$.factory.EBinOp(self.op2str(sym), self.$._tree, other._tree()));
              } else {
                res.set__sources(self.$._sources);
                res.set__tree(self._class_.$.factory.EBinOp(self.op2str(sym), self.$._tree, Eval.make_const(self._class_.$.factory, res)));
              }
            }
          }
          return res;
        } else {
          return self.$._val.send.apply(self.$._val, [block, sym].concat(args));
        }
      };

      this.set_== = function(other) {
        var self = this; 
        return self.method_missing("===", other);
      };

      this.valueOf = function() {
        var self = this; 
        return self.$._val.valueOf();
      };

      this.to_s = function() {
        var self = this; 
        return self.$._val;
      };

      this.eql_P = function(other) {
        var self = this; 
        return self.$._val.eql_P(other);
      };

      this.hash = function() {
        var self = this; 
        return self.$._val.hash();
      };
    });

  Proxy = {
    Proxy: Proxy,
    proxify: function(obj) {
      var self = this; 
      return obj.fields().each(function(f) {
        if (f.traversal()) {
          if (f.type().Primitive_P()) {
            return obj._set(f.name(), Proxy.new(obj._get(f.name())));
          } else if (! f.many()) {
          } else {
          }
        }
      });
    },

  };
  return Proxy;
})
