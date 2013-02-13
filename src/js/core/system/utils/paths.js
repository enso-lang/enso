define([
],
function() {

  var Paths ;

  var Path = MakeClass( {
    _class_: {
      parse: function(str) {
        var self = this; 
        var original, str, base, elts;
        var super$ = this.super$.parse;
        original = str;
        str = str.gsub("\\\\\\\\", "");
        if (str._get(0) == "/") {
          str = str.slice(1, 1000);
          base = [Root.new()];
        } else {
          base = [];
        }
        elts = (base + self.scan(str)).flatten();
        return Path.new(elts);
      },

      scan: function(str) {
        var self = this; 
        var n, base, index;
        var super$ = this.super$.scan;
        return str.split("/").map(function(part) {
          if (part == ".") {
            return [];
          } else if ((n = part.index("[")) && part.slice(- 1) == "]") {
            base = part.slice(0, n);
            index = part.slice(n + 1, (part.length() - n) - 2);
            return [Field.new(base), Key.new(index)];
          } else {
            return Field.new(part);
          }
        });
      }
    },

    elts: function() { return this.$.elts },

    initialize: function(elts) {
      var self = this; 
      if (elts === undefined) elts = [];
      var super$ = this.super$.initialize;
      return self.$.elts = elts;
    },

    reset_in_place: function() {
      var self = this; 
      var super$ = this.super$.reset_in_place;
      return self.$.elts = [];
    },

    prepend_in_place: function(path) {
      var self = this; 
      var super$ = this.super$.prepend_in_place;
      return self.$.elts = path.elts() + self.$.elts;
    },

    extend: function(path) {
      var self = this; 
      var super$ = this.super$.extend;
      return Path.new(self.elts() + path.elts());
    },

    deref_P: function(scan, root) {
      var self = this; 
      if (root === undefined) root = scan;
      var root;
      var super$ = this.super$.deref_P;
      try {
        return self.deref(scan, root = scan);
      } catch ( DUMMY ) {
        return false;
      }
    },

    deref: function(scan, root) {
      var self = this; 
      if (root === undefined) root = scan;
      var scan;
      var super$ = this.super$.deref;
      self.elts().each(function(elt) {
        if (! scan) {
          self.raise(S("cannot dereference ", elt, " on ", scan));
        }
        return scan = elt.deref(scan, root);
      });
      return scan;
    },

    search: function(root, base, target) {
      var self = this; 
      var super$ = this.super$.search;
      return self.searchElts(function(item, bindings) {
        if (target.equals(item)) {
          return bindings;
        }
      }, self.elts(), base, root, new EnsoHash ( { } ));
    },

    searchElts: function(action, todo, scan, root, bindings) {
      var self = this; 
      var super$ = this.super$.searchElts;
      if (todo.nil_P() || todo.first().nil_P()) {
        return action.call(scan, bindings);
      } else {
        return todo.first().search(function(item, newBinds) {
          return self.searchElts(todo._get(Range.new(1, - 1)), item, root, newBinds);
        }, scan, root, bindings);
      }
    },

    field: function(name) {
      var self = this; 
      var super$ = this.super$.field;
      return self.descend(Field.new(name));
    },

    key: function(key) {
      var self = this; 
      var super$ = this.super$.key;
      return self.descend(Key.new(key));
    },

    index: function(index) {
      var self = this; 
      var super$ = this.super$.index;
      return self.descend(Index.new(index));
    },

    root_P: function() {
      var self = this; 
      var super$ = this.super$.root_P;
      return self.elts().empty_P();
    },

    lvalue_P: function() {
      var self = this; 
      var super$ = this.super$.lvalue_P;
      return ! self.root_P() && self.last().is_a_P(Field);
    },

    assign: function(root, obj) {
      var self = this; 
      var super$ = this.super$.assign;
      if (! self.lvalue_P()) {
        self.raise(S("Can only assign to lvalues not to ", self));
      }
      return self.owner().deref(root) ._set( self.last().name() , obj );
    },

    assign_and_coerce: function(root, value) {
      var self = this; 
      var obj, fld, value;
      var super$ = this.super$.assign_and_coerce;
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
      return self.owner().deref(root) ._set( self.last().name() , value );
    },

    insert: function(root, obj) {
      var self = this; 
      var super$ = this.super$.insert;
      return self.deref(root).push(obj);
    },

    insert_at: function(root, key, obj) {
      var self = this; 
      var super$ = this.super$.insert_at;
      return self.deref(root) ._set( key , obj );
    },

    owner: function() {
      var self = this; 
      var super$ = this.super$.owner;
      return Path.new(self.elts()._get(Range.new(0, - 2)));
    },

    last: function() {
      var self = this; 
      var super$ = this.super$.last;
      return self.elts().last();
    },

    to_s: function() {
      var self = this; 
      var res;
      var super$ = this.super$.to_s;
      res = self.elts().join();
      if (res == "") {
        return "/";
      } else {
        return res;
      }
    },

    descend: function(elt) {
      var self = this; 
      var super$ = this.super$.descend;
      return Path.new([elt]);
    }
  });

  var Elt = MakeClass( {
  });

  var Root = MakeClass( Elt, {
    deref: function(obj, root) {
      var self = this; 
      var super$ = this.super$.deref;
      return root;
    },

    search: function(action, obj, root, bindings) {
      var self = this; 
      var super$ = this.super$.search;
      return action.call(root, bindings);
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return "ROOT";
    }
  });

  var Field = MakeClass( Elt, {
    name: function() { return this.$.name },

    initialize: function(name) {
      var self = this; 
      var super$ = this.super$.initialize;
      return self.$.name = name;
    },

    deref: function(obj, root) {
      var self = this; 
      var super$ = this.super$.deref;
      return obj._get(self.$.name);
    },

    search: function(action, obj, root, bindings) {
      var self = this; 
      var super$ = this.super$.search;
      if (! obj.nil_P() && obj.schema_class().all_fields()._get(self.$.name)) {
        return action.call(obj._get(self.$.name), bindings);
      }
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return S("/", self.$.name);
    }
  });

  var Index = MakeClass( Elt, {
    index: function() { return this.$.index },

    initialize: function(index) {
      var self = this; 
      var super$ = this.super$.initialize;
      return self.$.index = index;
    },

    deref: function(obj, root) {
      var self = this; 
      var super$ = this.super$.deref;
      return obj._get(self.$.index);
    },

    search: function(action, obj, root, bindings) {
      var self = this; 
      var super$ = this.super$.search;
      if (self.$.index.is_a_P(PathVar)) {
        return obj.find_first_with_index(function(item, i) {
          return action.call(item, new EnsoHash ( { } ).update(bindings));
        });
      } else {
        return action.call(obj._get(self.$.index), bindings);
      }
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return S("[", self.$.index, "]");
    }
  });

  var Key = MakeClass( Elt, {
    key: function() { return this.$.key },

    initialize: function(key) {
      var self = this; 
      var super$ = this.super$.initialize;
      return self.$.key = key;
    },

    deref: function(obj, root) {
      var self = this; 
      var super$ = this.super$.deref;
      return obj._get(self.$.key);
    },

    search: function(action, obj, root, bindings) {
      var self = this; 
      var super$ = this.super$.search;
      if (self.$.key.is_a_P(PathVar)) {
        return obj.find_first_pair(function(k, item) {
          return action.call(item, new EnsoHash ( { } ).update(bindings));
        });
      } else {
        return action.call(obj._get(self.$.key), bindings);
      }
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return S("[", self.escape(self.$.key.to_s()), "]");
    },

    escape: function(s) {
      var self = this; 
      var super$ = this.super$.escape;
      return s.gsub("]", "\\\\\\\\]").gsub("[", "\\\\\\\\[");
    }
  });

  var PathVar = MakeClass( {
    initialize: function(name) {
      var self = this; 
      var super$ = this.super$.initialize;
      return self.$.name = name;
    },

    name: function() { return this.$.name },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.name;
    }
  });

  Paths = {
    parse: function(str) {
      p = Path.parse(str);
      return p;
    } ,

    new: function(elts) {
      if (elts === undefined) elts = [];
      return Path.new(elts);
    } ,

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
