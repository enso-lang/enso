define([
],
function() {

  var Schema ;

  Schema = {
    class_key: function(klass) {
      return klass.fields().find(function(f) {
        return f.key() && f.type().Primitive_P();
      });
    },

    object_key: function(obj) {
      return obj._get(self.class_key(obj.schema_class()).name());
    },

    is_keyed_P: function(klass) {
      return ! klass.Primitive_P() && ! (self.class_key(klass) == null);
    },

    lookup: function(block, obj) {
      res = block(obj);
      if (res) {
        return res;
      } else if (obj.supers().empty_P()) {
        return null;
      } else {
        return obj.supers().find_first(function(o) {
          return self.lookup(o);
        });
      }
    },

    subclass_P: function(a, b) {
      if (a == null || b == null) {
        return false;
      } else if (a.name() == System.test_type(b, String)
        ? b
        : b.name()
      ) {
        return true;
      } else {
        return a.supers().any_P(function(sup) {
          return self.subclass_P(sup, b);
        });
      }
    },

    class_minimum: function(a, b) {
      if (b == null) {
        return a;
      } else if (a == null) {
        return b;
      } else if (self.subclass_P(a, b)) {
        return a;
      } else if (self.subclass_P(b, a)) {
        return b;
      } else {
        return null;
      }
    },

    map: function(block, obj) {
      if (obj == null) {
        return null;
      } else {
        res = block(obj);
        obj.schema_class().fields().each(function(f) {
          if (f.traversal() && ! f.type().Primitive_P()) {
            if (! f.many()) {
              return Schema.map(obj._get(f.name()));
            } else {
              return res._get(f.name()).keys().each(function(k) {
                return Schema.map(obj._get(f.name())._get(k));
              });
            }
          }
        });
        return res;
      }
    },

  };
  return Schema;
})
