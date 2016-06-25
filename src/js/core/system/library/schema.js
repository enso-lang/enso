define([], (function () {
  var Schema;
  (Schema = {
    class_minimum: (function (a, b) {
      var self = this;
      if ((b == null)) { 
        return a; 
      }
      else { 
        if ((a == null)) { 
          return b; 
        }
        else { 
          if (self.subclass_P(a, b)) { 
            return a; 
          }
          else { 
            if (self.subclass_P(b, a)) { 
              return b; 
            }
            else { 
              return null;
            }
          }
        }
      }
    }),
    subclass_P: (function (a, b) {
      var self = this;
      if (((a == null) || (b == null))) { 
        return false; 
      }
      else { 
        if ((a.name() == (System.test_type(b, String) ? b : b.name()))) { 
          return true; 
        }
        else { 
          return a.supers().any_P((function (sup) {
            return self.subclass_P(sup, b);
          }));
        }
      }
    }),
    lookup: (function (block, obj) {
      var self = this;
      var res;
      (res = block(obj));
      if (res) { 
        return res; 
      }
      else { 
        if (obj.supers().empty_P()) { 
          return null; 
        }
        else { 
          return obj.supers().find_first((function (o) {
            return self.lookup(block, o);
          }));
        }
      }
    }),
    map: (function (block, obj) {
      var self = this;
      var res;
      if ((obj == null)) { 
        return null; 
      } 
      else {
             (res = block(obj));
             obj.schema_class().fields().each((function (f) {
               if ((f.traversal() && (!f.type().Primitive_P()))) {
                 if ((!f.many())) { 
                   return self.map(block, obj._get(f.name())); 
                 }
                 else { 
                   return res._get(f.name()).keys().each((function (k) {
                     return self.map(block, obj._get(f.name())._get(k));
                   }));
                 }
               }
             }));
             return res;
           }
    }),
    object_key: (function (obj) {
      var self = this;
      return obj._get(obj.schema_class().key().name());
    })
  });
  return Schema;
}));