define([
],
function() {
  var SPPF ;
  var BaseNode = MakeClass("BaseNode", null, [],
    function() {
      this.nodes = function() {
        var self = this; 
        return self._class_.$.nodes;
      };

      this.new = function() {
        var self = this; 
        var args = compute_rest_arguments(arguments, 0 );
        if (! self._class_.$.nodes.has_key_P(args)) {
          return self._class_.$.nodes._set(args, super$.new.call(self));
        } else {
          return self._class_.$.nodes._get(args);
        }
      };
    },
    function(super$) {
      this.type = function() { return this.$.type };

      this.starts = function() { return this.$.starts };

      this.ends = function() { return this.$.ends };

      this.kids = function() {
        var self = this; 
        return [];
      };

      this.initialize = function(starts, ends, type) {
        var self = this; 
        self.$.starts = starts;
        self.$.ends = ends;
        self.$.type = type;
        return self.$.hash = (29 * self.class().to_s().hash() + 37 * starts) + 17 * ends;
      };

      this.build = function(owner, accu, field, fixes, paths, fact, orgs) {
        var self = this; 
        return self.type().build_spine(self, owner, accu, field, fixes, paths, fact, orgs);
      };

      this.build_kids = function(owner, accu, field, fixes, paths, fact, orgs) {
        var self = this; 
        if (self.kids().length() > 1) {
          self.raise(Ambiguity.new(self));
        }
        if (! self.kids().empty_P()) {
          self.kids().first().build(owner, accu, field, fixes, paths, fact, orgs);
        }
        return null;
      };

      this.hash = function() {
        var self = this; 
        return self.$.hash;
      };

      this.eql_P = function(o) {
        var self = this; 
        return self.equals(o);
      };

      this.origin = function(orgs) {
        var self = this; 
        var path, offset, length, start_line, start_column, end_line, end_column;
        path = orgs.path();
        offset = orgs.offset(self.starts());
        length = self.ends() - self.starts();
        start_line = orgs.line(self.starts());
        start_column = orgs.column(self.starts());
        end_line = orgs.line(self.ends());
        end_column = orgs.column(self.ends());
        return Location.new(path, offset, length, start_line, start_column, end_line, end_column);
      };
    });

  var Empty = MakeClass("Empty", BaseNode, [],
    function() {
    },
    function(super$) {
      this.initialize = function(pos, type) {
        var self = this; 
        return super$.initialize.call(self, pos, pos, type);
      };

      this.equals = function(x) {
        var self = this; 
        if (! System.test_type(x, Empty)) {
          return false;
        } else {
          return true;
        }
      };

      this.build = function(owner, accu, field, fixes, paths, fact, orgs) {
        var self = this; 
      };
    });

  var Leaf = MakeClass("Leaf", BaseNode, [],
    function() {
    },
    function(super$) {
      this.value = function() { return this.$.value };

      this.ws = function() { return this.$.ws };

      this.initialize = function(starts, ends, type, value, ws) {
        var self = this; 
        if (type === undefined) type = null;
        if (value === undefined) value = null;
        if (ws === undefined) ws = null;
        super$.initialize.call(self, starts, ends, type);
        self.$.value = value;
        self.$.ws = ws;
        return self.$.hash = self.$.hash + 13 * value.hash();
      };

      this.equals = function(x) {
        var self = this; 
        if (! System.test_type(x, Leaf)) {
          return false;
        } else {
          return self.value().equals(x.value());
        }
      };

      this.ends = function() {
        var self = this; 
        return self.super() + self.ws().length();
      };

      this.to_s = function() {
        var self = this; 
        return S("T('", self.value(), "', ws = '", self.ws(), "')");
      };
    });

  var Node = MakeClass("Node", BaseNode, [],
    function() {
      this.new = function(item, z, w) {
        var self = this; 
        var t, x, k, i, s, j, y;
        if (item.dot() == 1 && item.elements().length() > 1) {
          return w;
        } else {
          t = item;
          if (item.dot() == item.elements().length()) {
            t = item.expression();
          }
          x = w.type();
          k = w.starts();
          i = w.ends();
          if (z != null) {
            s = z.type();
            j = z.starts();
            y = super$.new.call(self, j, i, t);
            y.add_kid(Pack.new(item, k, z, w));
          } else {
            y = super$.new.call(self, k, i, t);
            y.add_kid(Pack.new(item, k, null, w));
          }
          return y;
        }
      };
    },
    function(super$) {
      this.kids = function() { return this.$.kids };

      this.initialize = function(starts, ends, type) {
        var self = this; 
        super$.initialize.call(self, starts, ends, type);
        self.$.kids = [];
        return self.$.hash = self.$.hash + 13 * type.hash();
      };

      this.add_kid = function(pn) {
        var self = this; 
        var includes;
        includes = false;
        self.$.kids.each(function(k) {
          if (k.equals(pn)) {
            return includes = true;
          }
        });
        if (includes) {
          return null;
        } else {
          return self.$.kids.push(pn);
        }
      };

      this.equals = function(x) {
        var self = this; 
        if (! System.test_type(x, Node)) {
          return false;
        } else {
          return self.type().equals(x.type());
        }
      };
    });

  var Pack = MakeClass("Pack", null, [],
    function() {
    },
    function(super$) {
      this.item = function() { return this.$.item };

      this.pivot = function() { return this.$.pivot };

      this.left = function() { return this.$.left };

      this.right = function() { return this.$.right };

      this.initialize = function(item, pivot, left, right) {
        var self = this; 
        self.$.item = item;
        self.$.pivot = pivot;
        self.$.left = left;
        return self.$.right = right;
      };

      this.hash = function() {
        var self = this; 
        return ("pack".hash() + 7 * self.item().hash()) + 31 * self.pivot();
      };

      this.build = function(owner, accu, field, fixes, paths, fact, orgs) {
        var self = this; 
        if (self.left()) {
          self.left().build(owner, accu, field, fixes, paths, fact, orgs);
        }
        return self.right().build(owner, accu, field, fixes, paths, fact, orgs);
      };

      this.equals = function(x) {
        var self = this; 
        if (! System.test_type(x, Pack)) {
          return false;
        } else {
          return self.item().equals(x.item()) && self.pivot() == x.pivot();
        }
      };

      this.kids = function() {
        var self = this; 
        if (self.left()) {
          return [self.left(), self.right()];
        } else {
          return [self.right()];
        }
      };
    });

  SPPF = {
    BaseNode: BaseNode,
    Empty: Empty,
    Leaf: Leaf,
    Node: Node,
    Pack: Pack,

  };
  return SPPF;
})
