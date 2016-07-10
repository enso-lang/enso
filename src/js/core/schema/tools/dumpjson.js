define(["core/system/utils/paths", "core/system/library/schema", "core/system/boot/meta_schema", "json"], (function (Paths, Schema, MetaSchema, Json) {
  var Dumpjson;
  var Fixup = MakeClass("Fixup", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (obj, field, spec) {
      var self = this;
      (self.$.obj = obj);
      (self.$.field = field);
      return (self.$.spec = spec);
    }));
    (this.apply = (function (root) {
      var self = this;
      var collection;
      if ((!self.$.field.many())) { 
        return self.$.obj._set(self.$.field.name(), MetaSchema.path_eval(self.$.spec, root)); 
      } 
      else {
             (collection = self.$.obj._get(self.$.field.name()));
             return self.$.spec.each((function (path) {
               return collection.push(MetaSchema.path_eval(path, root));
             }));
           }
    }));
  }));
  var FromJSON = MakeClass("FromJSON", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (factory) {
      var self = this;
      return (self.$.factory = factory);
    }));
    (this.decode = (function (this_V) {
      var self = this;
      var res;
      (self.$.fixups = []);
      (res = self.from_json(this_V));
      self.$.fixups.each((function (fix) {
        return fix.apply(res);
      }));
      return res;
    }));
    (this.from_json = (function (this_V) {
      var self = this;
      var obj;
      if ((this_V == null)) { 
        return null; 
      } 
      else {
             (obj = self.$.factory._get(this_V._get("class")));
             obj.schema_class().fields().each((function (f) {
               var val, fname;
               if (f.type().Primitive_P()) {
                 (val = this_V._get(S("", f.name(), "=")));
                 if ((!(val == null))) {
                   return obj._set(f.name(), val);
                 }
               }
               else {
                 if ((!f.many())) { 
                   if ((this_V._get(f.name()) == null)) { 
                     return obj._set(f.name(), null); 
                   }
                   else { 
                     if (f.traversal()) { 
                       return obj._set(f.name(), self.from_json(this_V._get(f.name()))); 
                     }
                     else { 
                       return self.$.fixups.push(Fixup.new(obj, f, this_V._get(f.name())));
                     }
                   } 
                 } 
                 else {
                        (fname = (f.type().key() ? S("", f.name(), "#") : f.name()));
                        if ((!(this_V._get(fname) == null))) {
                          if (f.traversal()) { 
                            return this_V._get(fname).each((function (o) {
                              return obj._get(f.name()).push(self.from_json(o));
                            })); 
                          }
                          else { 
                            return self.$.fixups.push(Fixup.new(obj, f, this_V._get(fname)));
                          }
                        }
                      }
               }
             }));
             return obj;
           }
    }));
  }));
  (Dumpjson = {
    to_json: (function (this_V, do_all) {
      var self = this;
      (do_all = (((typeof do_all) !== "undefined") ? do_all : false));
      var e;
      if ((this_V == null)) { 
        return null; 
      } 
      else {
             (e = (new EnsoHash({
               
             })));
             e._set("class", this_V.schema_class().name());
             this_V.schema_class().fields().each((function (f) {
               var name, ef, val;
               (name = f.name());
               (val = this_V._get(name));
               if ((do_all || val)) {
                 if (f.type().Primitive_P()) { 
                   return e._set(S("", name, "="), val); 
                 }
                 else { 
                   if (f.many()) {
                     if (f.type().key()) {
                       (name = (name + "#"));
                     }
                     (ef = []);
                     if (f.traversal()) { 
                       val.each((function (fobj) {
                         return ef.push(self.to_json(fobj, do_all));
                       })); 
                     }
                     else { 
                       val.each((function (fobj) {
                         return ef.push(self.fixup_path(fobj));
                       }));
                     }
                     if ((do_all || (ef.size() > 0))) {
                       return e._set(name, ef);
                     }
                   }
                   else {
                     if ((do_all || (!(val == null)))) {
                       if (f.traversal()) { 
                         return e._set(name, (val && self.to_json(val, do_all))); 
                       }
                       else { 
                         return e._set(name, (val && self.fixup_path(val)));
                       }
                     }
                   }
                 }
               }
             }));
             return e;
           }
    }),
    Fixup: Fixup,
    FromJSON: FromJSON,
    fixup_path: (function (obj) {
      var self = this;
      var path;
      (path = obj._path().to_s());
      if ((path == "root")) { 
        return (path = ""); 
      }
      else { 
        return (path = path.slice(5, 999));
      }
    }),
    from_json: (function (factory, text) {
      var self = this;
      return FromJSON.new(factory).decode(text);
    })
  });
  return Dumpjson;
}));