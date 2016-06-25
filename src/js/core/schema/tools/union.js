define(["core/schema/code/factory"], (function (Factory) {
  var Union;
  var CopyInto = MakeClass("CopyInto", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (factory) {
      var self = this;
      (self.$.memo = (new EnsoHash({
        
      })));
      return (self.$.factory = factory);
    }));
    (this.copy = (function (a, b) {
      var self = this;
      self.build(a, b);
      return self.link(true, a, b);
    }));
    (this.build = (function (a, b) {
      var self = this;
      var new_V;
      if ((!(a == null))) {
        if (((a && b) && (a.schema_class().name() != b.schema_class().name()))) {
          self.raise(S("Union of incompatible objects ", a, " and ", b, ""));
        }
        self.$.memo._set(a._id(), (new_V = (b || self.$.factory._get(a.schema_class().name()))));
        return new_V.schema_class().fields().each((function (field) {
          var a_val, b_val;
          (a_val = (function () {
            try {return a._get(field.name());
                 
            }
            catch (caught$1238) {
              
                return null;
            }
          })());
          (b_val = (function () {
            try {return b._get(field.name());
                 
            }
            catch (caught$1325) {
              
                return null;
            }
          })());
          if (((!(a_val == null)) || (!(b_val == null)))) { 
            if (field.type().Primitive_P()) { 
              if ((!(a_val == null))) {
                if (((a && b) && (a_val != b_val))) {
                  puts(S("UNION WARNING: changing ", new_V, ".", field.name(), " from '", b_val, "' to '", a_val, "'"));
                }
                return new_V._set(field.name(), a_val);
              } 
            }
            else { 
              if (field.traversal()) { 
                if ((!field.many())) { 
                  return self.build(a_val, b_val); 
                }
                else { 
                  return a_val.each_with_match((function (a_item, b_item) {
                    return self.build(a_item, b_item);
                  }), b_val);
                } 
              } 
              else {
                   }
            } 
          }
          else { 
            if ((!(new_V._get(field.name()) == null))) {
              return puts(S("skipping ", new_V, ".", field.name(), " as ", new_V._get(field.name()), ""));
            }
          }
        }));
      }
    }));
    (this.link = (function (traversal, a, b) {
      var self = this;
      var new_V;
      if ((a == null)) { 
        return b; 
      } 
      else {
             (new_V = self.$.memo._get(a._id()));
             if ((!new_V)) {
               self.p(self.$.memo);
               self.raise(S("Traversal did not visit every object a=", a, " b=", b, ""));
             }
             if (traversal) {
               a.schema_class().fields().each((function (field) {
                 var val, a_val, b_val;
                 (a_val = a._get(field.name()));
                 (b_val = (b && b._get(field.name())));
                 if ((!field.type().Primitive_P())) {
                   if ((!field.many())) {
                     (val = self.link(field.traversal(), a_val, b_val));
                     return new_V._set(field.name(), val);
                   }
                   else {
                     return a_val.each_with_match((function (a_item, b_item) {
                       var item;
                       (item = self.link(field.traversal(), a_item, b_item));
                       return new_V._get(field.name()).push(item);
                     }), b_val);
                   }
                 }
               }));
             }
             return new_V;
           }
    }));
  }));
  (Union = {
    Clone: (function (a) {
      var self = this;
      return self.Copy(a.factory(), a);
    }),
    Union: (function (factory) {
      var self = this;
      var parts = compute_rest_arguments(arguments, this.Union.length);
      var copier, result;
      (copier = CopyInto.new(factory));
      (result = null);
      parts.each((function (part) {
        return (result = copier.copy(part, result));
      }));
      return result.finalize();
    }),
    union: (function (a, b) {
      var self = this;
      var f;
      (f = Factory.new(a._graph_id().schema()));
      return Union(f, a, b);
    }),
    Copy: (function (factory, a) {
      var self = this;
      return CopyInto.new(factory).copy(a, null).finalize();
    }),
    CopyInto: (function (factory, a, b) {
      var self = this;
      return CopyInto.new(factory).copy(a, b);
    })
  });
  return Union;
}));