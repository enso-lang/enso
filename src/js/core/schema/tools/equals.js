define([
],
function() {
  var Equals ;

  var Equals = MakeClass("Equals", null, [],
    function() {
      this.equals = function(a, b) {
        var self = this; 
        return self.new().equals(a, b);
      };
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
        return self.$.memo = new EnsoHash ({ });
      };

      this.equals = function(a, b) {
        var self = this; 
        var res, a_val, b_val;
        if (a == b) {
          return true;
        } else if ((a == null || b == null) || a.schema_class().name() != b.schema_class().name()) {
          return false;
        } else if (self.$.memo._get([a, b])) {
          return true;
        } else {
          res = true;
          self.$.memo._set([a, b], true);
          a.schema_class().fields().each(function(field) {
            a_val = a._get(field.name());
            b_val = b._get(field.name());
            if (field.type().Primitive_P()) {
              if (a_val != b_val) {
                return res = false;
              }
            } else if (! field.many()) {
              if (! self.equals(a_val, b_val)) {
                puts(S("fail2 ", a_val, " ", b_val));
                return res = false;
              }
            } else if (System.test_type(a_val, Factory.List)) {
              if (! self.equals_list(a_val, b_val)) {
                return res = false;
              }
            } else if (System.test_type(a_val, Factory.Set)) {
              if (! self.equals_set(a_val, b_val)) {
                return res = false;
              }
            }
          });
          return res;
        }
      };

      this.equals_list = function(l1, l2) {
        var self = this; 
        var res;
        if (l1.size() != l2.size()) {
          return false;
        } else {
          res = true;
          l1.keys().each(function(i) {
            if (! self.equals(l1._get(i), l2._get(i))) {
              return res = false;
            }
          });
          return res;
        }
      };

      this.equals_set = function(l1, l2) {
        var self = this; 
        var res;
        if (l1.size() != l2.size()) {
          return false;
        } else {
          res = true;
          l1.keys().each(function(i) {
            if (! self.equals(l1._get(i), l2._get(i))) {
              return res = false;
            }
          });
          return res;
        }
      };
    });

  Equals = {
    equals: function(a, b) {
      var self = this; 
      return Equals.equals(a, b);
    },

    Equals: Equals,

  };
  return Equals;
})
