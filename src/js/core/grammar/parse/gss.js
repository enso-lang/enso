define([
],
function() {
  var GSS ;
  var GSS = MakeClass("GSS", null, [],
    function() {
      this.new = function() {
        var self = this; 
        var args = compute_rest_arguments(arguments, 0);
        if (! self._class_.$.nodes.has_key_P(args)) {
          return self._class_.$.nodes._set(args, super$.new.call(self));
        } else {
          return self._class_.$.nodes._get(args);
        }
      };

      this.nodes = function() {
        var self = this; 
        return self._class_.$.nodes;
      };
    },
    function(super$) {
      this.item = function() { return this.$.item };

      this.pos = function() { return this.$.pos };

      this.edges = function() { return this.$.edges };

      this.initialize = function(item, pos) {
        var self = this; 
        self.$.item = item;
        self.$.pos = pos;
        self.$.edges = new EnsoHash ({ });
        return self.$.hash = item.hash() * 3 + pos * 17;
      };

      this.add_edge = function(node, gss) {
        var self = this; 
        if (! self.edges().include_P(node)) {
          self.edges()._set(node, []);
        }
        if (self.edges()._get(node).include_P(gss)) {
          return false;
        } else {
          self.edges()._get(node).push(gss);
          return true;
        }
      };

      this.equals = function(o) {
        var self = this; 
        if (self.equal_P(o)) {
          return true;
        } else if (! System.test_type(o, GSS)) {
          return false;
        } else {
          return self.item().equals(o.item()) && self.pos() == o.pos();
        }
      };

      this.eql_P = function(o) {
        var self = this; 
        return self.equals(o);
      };

      this.hash = function() {
        var self = this; 
        return self.$.hash;
      };

      this.to_s = function() {
        var self = this; 
        return S("GSS(", self.item(), " @ ", self.pos(), ")");
      };
    });

  GSS = {
    GSS: GSS,

  };
  return GSS;
})
