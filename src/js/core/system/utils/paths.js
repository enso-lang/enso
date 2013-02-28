define([
],
function() {
  var Paths ;

  var Path = MakeClass("Path", null, [],
    function() {
      this.parse = function(str) {
        var self = this; 
        var original, str, base, elts;
        original = str;
        str = str.gsub("\\\\", "");
        if (str._get(0) == "/") {
          str = str.slice(1, 1000);
          base = [Root.new()];
        } else {
          base = [];
        }
        elts = base.concat(self.scan(str));
        return Path.new(elts);
      };

      this.scan = function(str) {
        var self = this; 
        var result, n, base, index;
        result = [];
        str.split("/").each(function(part) {
          if ((n = part.index("[")) && part.slice(- 1) == "]") {
            base = part.slice(0, n);
            index = part.slice(n + 1, (part.length - n) - 2);
            result.push(Field.new(base));
            return result.push(Key.new(index));
          } else if (part != ".") {
            return result.push(Field.new(part));
          }
        });
        return result;
      };
    },
    function(super$) {
      this.elts = function() { return this.$.elts };

      this.initialize = function(elts) {
        var self = this; 
        if (elts === undefined) elts = [];
        return self.$.elts = elts;
      };

      this.reset_in_place = function() {
        var self = this; 
        return self.$.elts = [];
      };

      this.prepend_in_place = function(path) {
        var self = this; 
        return self.$.elts = path.elts() + self.$.elts;
      };

      this.extend = function(path) {
        var self = this; 
        return Path.new(self.elts() + path.elts());
      };

      this.deref_P = function(scan, root) {
        var self = this; 
        if (root === undefined) root = scan;
        var root;
        try {
          return self.deref(scan, root = scan);
        } catch ( DUMMY ) {
          return false;
        }
      };

      this.deref = function(scan, root) {
        var self = this; 
        if (root === undefined) root = scan;
        var scan;
        self.elts().each(function(elt) {
          if (! scan) {
            self.raise(S("cannot dereference ", elt, " on ", scan));
          }
          return scan = elt.deref(scan, root);
        });
        return scan;
      };

      this.search = function(root, base, target) {
        var self = this; 
        return self.searchElts(function(item, bindings) {
          if (target.equals(item)) {
            return bindings;
          }
        }, self.elts(), base, root, new EnsoHash ( { } ));
      };

      this.searchElts = function(action, todo, scan, root, bindings) {
        var self = this; 
        if (todo == null || todo.first() == null) {
          return action(scan, bindings);
        } else {
          return todo.first().search(function(item, newBinds) {
            return self.searchElts(action, todo._get(Range.new(1, - 1)), item, root, newBinds);
          }, scan, root, bindings);
        }
      };

      this.field = function(name) {
        var self = this; 
        return self.descend(Field.new(name));
      };

      this.key = function(key) {
        var self = this; 
        return self.descend(Key.new(key));
      };

      this.index = function(index) {
        var self = this; 
        return self.descend(Index.new(index));
      };

      this.root_P = function() {
        var self = this; 
        return self.elts().empty_P();
      };

      this.lvalue_P = function() {
        var self = this; 
        return ! self.root_P() && System.test_type(self.last(), Field);
      };

      this.assign = function(root, obj) {
        var self = this; 
        if (! self.lvalue_P()) {
          self.raise(S("Can only assign to lvalues not to ", self));
        }
        return self.owner().deref(root)._set(self.last().name(), obj);
      };

      this.assign_and_coerce = function(root, value) {
        var self = this; 
        var obj, fld, value;
        if (! self.lvalue_P()) {
          self.raise(S("Can only assign to lvalues not to ", self));
        }
        obj = self.owner().deref(root);
        fld = obj.schema_class().fields()._get(self.last().name());
        if (fld.type().Primitive_P()) {
          value = fld.type().name() == "str"
            ? value.to_s()
            : fld.type().name() == "int"
              ? value.to_i()
              : fld.type().name() == "bool"
                ? value.to_s() == "true"
                  ? true
                  : false
                : fld.type().name() == "real"
                  ? value.to_f()
                  : self.raise(S("Unknown primitive type: ", fld.type().name()))
          ;
        }
        return self.owner().deref(root)._set(self.last().name(), value);
      };

      this.insert = function(root, obj) {
        var self = this; 
        return self.deref(root).push(obj);
      };

      this.insert_at = function(root, key, obj) {
        var self = this; 
        return self.deref(root)._set(key, obj);
      };

      this.owner = function() {
        var self = this; 
        return Path.new(self.elts()._get(Range.new(0, - 2)));
      };

      this.last = function() {
        var self = this; 
        return self.elts().last();
      };

      this.to_s = function() {
        var self = this; 
        var res;
        res = self.elts().join();
        if (res == "") {
          return "/";
        } else {
          return res;
        }
      };

      this.descend = function(elt) {
        var self = this; 
        return Path.new([elt]);
      };
    });

  var Elt = MakeClass("Elt", null, [],
    function() {
    },
    function(super$) {
    });

  var Root = MakeClass("Root", Elt, [],
    function() {
    },
    function(super$) {
      this.deref = function(obj, root) {
        var self = this; 
        return root;
      };

      this.search = function(action, obj, root, bindings) {
        var self = this; 
        return action(root, bindings);
      };

      this.to_s = function() {
        var self = this; 
        return "ROOT";
      };
    });

  var Field = MakeClass("Field", Elt, [],
    function() {
    },
    function(super$) {
      this.name = function() { return this.$.name };

      this.initialize = function(name) {
        var self = this; 
        return self.$.name = name;
      };

      this.value = function() {
        var self = this; 
        return self.name();
      };

      this.deref = function(obj, root) {
        var self = this; 
        return obj._get(self.$.name);
      };

      this.search = function(action, obj, root, bindings) {
        var self = this; 
        if (! (obj == null) && obj.schema_class().all_fields()._get(self.$.name)) {
          return action(obj._get(self.$.name), bindings);
        }
      };

      this.to_s = function() {
        var self = this; 
        return S("/", self.$.name);
      };
    });

  var Index = MakeClass("Index", Elt, [],
    function() {
    },
    function(super$) {
      this.index = function() { return this.$.index };

      this.initialize = function(index) {
        var self = this; 
        return self.$.index = index;
      };

      this.value = function() {
        var self = this; 
        return self.index();
      };

      this.deref = function(obj, root) {
        var self = this; 
        return obj._get(self.$.index);
      };

      this.search = function(action, obj, root, bindings) {
        var self = this; 
        if (System.test_type(self.$.index, PathVar)) {
          return obj.find_first_with_index(function(item, i) {
            return action(item, new EnsoHash ( { } ).update(bindings));
          });
        } else {
          return action(obj._get(self.$.index), bindings);
        }
      };

      this.to_s = function() {
        var self = this; 
        return S("[", self.$.index, "]");
      };
    });

  var Key = MakeClass("Key", Elt, [],
    function() {
    },
    function(super$) {
      this.key = function() { return this.$.key };

      this.initialize = function(key) {
        var self = this; 
        return self.$.key = key;
      };

      this.value = function() {
        var self = this; 
        return self.key();
      };

      this.deref = function(obj, root) {
        var self = this; 
        return obj._get(self.$.key);
      };

      this.search = function(action, obj, root, bindings) {
        var self = this; 
        if (System.test_type(self.$.key, PathVar)) {
          return obj.find_first_pair(function(k, item) {
            return action(item, new EnsoHash ( { } ).update(bindings));
          });
        } else {
          return action(obj._get(self.$.key), bindings);
        }
      };

      this.to_s = function() {
        var self = this; 
        return S("[", self.escape(self.$.key.to_s()), "]");
      };

      this.escape = function(s) {
        var self = this; 
        return s.gsub("]", "\\\\]").gsub("[", "\\\\[");
      };
    });

  var PathVar = MakeClass("PathVar", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(name) {
        var self = this; 
        return self.$.name = name;
      };

      this.name = function() { return this.$.name };

      this.to_s = function() {
        var self = this; 
        return self.$.name;
      };
    });

  Paths = {
    parse: function(str) {
      p = Path.parse(str);
      return p;
    },

    new: function(elts) {
      if (elts === undefined) elts = [];
      return Path.new(elts);
    },

    Path: Path,
    Elt: Elt,
    Root: Root,
    Field: Field,
    Index: Index,
    Key: Key,
    PathVar: PathVar,

  };
  return Paths;
})