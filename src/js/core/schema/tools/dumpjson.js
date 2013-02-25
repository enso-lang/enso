define([
  "core/system/utils/paths",
  "core/system/library/schema",
  "json"
],
function(Paths, Schema, Json) {
  var Dumpjson ;

  var Fixup = MakeClass("Fixup", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(obj, field, spec) {
        var self = this; 
        self.$.obj = obj;
        self.$.field = field;
        return self.$.spec = spec;
      };

      this.apply = function(root) {
        var self = this; 
        var collection;
        if (! self.$.field.many()) {
          return self.$.obj._set(self.$.field.name(), Paths.parse(self.$.spec).deref(root));
        } else {
          collection = self.$.obj._get(self.$.field.name());
          return self.$.spec.each(function(path) {
            return collection.push(Paths.parse(path).deref(root));
          });
        }
      };
    });

  var FromJSON = MakeClass("FromJSON", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(factory) {
        var self = this; 
        return self.$.factory = factory;
      };

      this.parse = function(this_V) {
        var self = this; 
        var res;
        self.$.fixups = [];
        res = self.from_json(this_V);
        self.$.fixups.each(function(fix) {
          return fix.apply(res);
        });
        return res;
      };

      this.from_json = function(this_V) {
        var self = this; 
        var obj, fname;
        if (this_V == null) {
          return null;
        } else {
          obj = self.$.factory._get(this_V._get("class"));          
          obj.schema_class().fields().each(function(f) {
            if (f.type().Primitive_P()) {
              return obj._set(f.name(), this_V._get(S(f.name(), "=")));
            } else if (! f.many()) {
              if (this_V._get(f.name()) == null) {
                return obj._set(f.name(), null);
              } else if (f.traversal()) {
                return obj._set(f.name(), self.from_json(this_V._get(f.name())));
              } else {
                return self.$.fixups.push(Fixup.new(obj, f, this_V._get(f.name())));
              }
            } else {
              fname = Schema.is_keyed_P(f.type())
                ? S(f.name(), "#")
                : f.name()
              ;
              if (f.traversal()) {
                return this_V._get(fname).each(function(o) {
                  var v = self.from_json(o);
                  return obj._get(f.name()).push(v);
                });
              } else {
                return self.$.fixups.push(Fixup.new(obj, f, this_V._get(fname)));
              }
            }
          });
          return obj;
        }
      };
    });

  Dumpjson = {
    to_json: function(this_V, do_all) {
      if (do_all === undefined) do_all = false;
      if (this_V == null) {
        return null;
      } else {
        e = new EnsoHash ( { } );
        e._set("class", this_V.schema_class().name());
        this_V.schema_class().fields().each(function(f) {
          name = f.name();
          val = this_V._get(name);
          if (do_all || val) {
            if (f.type().Primitive_P()) {
              return e._set(S(name, "="), val);
            } else if (f.many()) {
              if (Schema.is_keyed_P(f.type())) {
                name = name + "#";
              }
              ef = [];
              if (f.traversal()) {
                val.each(function(fobj) {
                  return ef.push(Dumpjson.to_json(fobj, do_all));
                });
              } else {
                val.each(function(fobj) {
                  return ef.push(fobj._path().to_s());
                });
              }
              if (do_all || ef.length > 0) {
                return e._set(name, ef);
              }
            } else if (do_all || val) {
              if (f.traversal()) {
                return e._set(name, val && Dumpjson.to_json(val, do_all));
              } else {
                return e._set(name, val && val._path().to_s());
              }
            }
          }
        });
        return e;
      }
    },

    from_json: function(factory, this_V) {
      return FromJSON.new(factory).parse(this_V);
    },

    to_json_string: function(this_V) {
      return JSON.pretty_generate(Dumpjson.to_json(this_V, true));
    },

    from_json_string: function(str) {
      return Dumpjson.from_json(JSON.parse(str));
    },

    Fixup: Fixup,
    FromJSON: FromJSON,

  };
  return Dumpjson;
})
