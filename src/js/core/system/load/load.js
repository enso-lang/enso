define([
  "core/system/library/schema",
  "core/system/boot/meta_schema",
  "core/schema/tools/union",
  "core/system/load/cache"
],
function(Schema, MetaSchema, Union, Cache) {
  var Load ;

  var LoaderClass = MakeClass("LoaderClass", null, [],
    function() {
    },
    function(super$) {
      GRAMMAR_GRAMMAR = "grammar.grammar";

      SCHEMA_SCHEMA = "schema.schema";

      SCHEMA_GRAMMAR = "schema.grammar";

      GRAMMAR_SCHEMA = "grammar.schema";

      this.load = function(name, type) {
        var self = this; 
        if (type === undefined) type = null;
        var GRAMMAR_GRAMMAR, SCHEMA_SCHEMA, SCHEMA_GRAMMAR, GRAMMAR_SCHEMA;
        if (self.$.cache == null) {
          self.setup();
        }
        if (self.$.cache._get(name)) {
          return self.$.cache._get(name);
        } else {
          return self.load_in_place(name, type);
        }
      };

      this.load_in_place = function(name, type) {
        var self = this; 
        if (type === undefined) type = null;
        return self.$.cache._set(name, self._load(name, type));
      };

      this.load_text = function(type, factory, source, show) {
        var self = this; 
        if (show === undefined) show = false;
        var g, s, result;
        g = self.load(S(type, ".grammar"));
        s = self.load(S(type, ".schema"));
        result = Parse.load_raw(source, g, s, factory, show);
        return result.finalize();
      };

      this.load_cache = function(name, obj) {
        var self = this; 
        System.stderr().push(S("## caching ", name, "...\\n"));
        return self.$.cache._set(name, obj);
      };

      this._load = function(name, type) {
        var self = this; 
        var filename, parts, model, type, g, s, res;
        if (Cache.check_dep(name)) {
          System.stderr().push(S("## fetching ", name, "...\\n"));
          return Cache.load_cache(name);
        } else {
          filename = name.split("/")._get(- 1);
          if (type == null) {
            parts = filename.split(".");
            model = parts._get(0);
            type = parts._get(1);
          }
          g = self.load(S(type, ".grammar"));
          s = self.load(S(type, ".schema"));
          res = self.load_with_models(name, g, s);
          System.stderr().push(S("## caching ", name, "...\\n"));
          Cache.save_cache(filename, res);
          return res;
        }
      };

      this.setup = function() {
        var self = this; 
        var ss, gs, gg, sg;
        self.$.cache = new EnsoHash ( { } );
        System.stderr().push("Initializing...\\n");
        self.$.cache._set(SCHEMA_SCHEMA, ss = self.load_with_models("schema_schema.json", null, null));
        self.$.cache._set(GRAMMAR_SCHEMA, gs = self.load_with_models("grammar_schema.json", null, ss));
        self.$.cache._set(GRAMMAR_GRAMMAR, gg = self.load_with_models("grammar_grammar.json", null, gs));
        self.$.cache._set(SCHEMA_GRAMMAR, sg = self.load_with_models("schema_grammar.json", null, gs));
        self.$.cache._set(SCHEMA_SCHEMA, ss = self.update_xml("schema.schema"));
        self.$.cache._set(GRAMMAR_SCHEMA, gs = self.update_xml("grammar.schema"));
        self.$.cache._set(GRAMMAR_GRAMMAR, gg = self.update_xml("grammar.grammar"));
        return self.$.cache._set(SCHEMA_GRAMMAR, sg = self.update_xml("schema.grammar"));
      };

      this.update_xml = function(name) {
        var self = this; 
        var parts, model, type, res;
        if (Cache.check_dep(name)) {
          return self.$.cache._get(name);
        } else {
          parts = name.split(".");
          model = parts._get(0);
          type = parts._get(1);
          res = self.load_with_models(name, self.load(S(type, ".grammar")), self.load(S(type, ".schema")));
          System.stderr().push(S("## caching ", name, "...\\n"));
          Cache.save_cache(name, res);
          return res;
        }
      };

      this.patch_schema_pointers_in_place = function(obj, schema) {
        var self = this; 
        var all_classes, sc;
        all_classes = [];
        Schema.map(function(o) {
          all_classes.push(o);
          return o;
        }, obj);
        return all_classes.each(function(o) {
          return o.instance_eval(function() {
            sc = schema.types()._get(o.schema_class().name());
            self.define_singleton_value("schema_class", sc);
            return self.$.factory.instance_eval(function() {
              return self.$.schema = schema;
            });
          });
        });
      };

      this.load_with_models = function(name, grammar, schema, encoding) {
        var self = this; 
        if (encoding === undefined) encoding = null;
        return self.find_model(function(path) {
          return self.load_path(path, grammar, schema, encoding);
        }, name);
      };

      this.load_path = function(path, grammar, schema, encoding) {
        var self = this; 
        if (encoding === undefined) encoding = null;
        var result, name, header, str, a, fnames;
        if (path.end_with_P(".xml") || path.end_with_P(".json")) {
          if (schema == null) {
            System.stderr().push(S("## booting ", path, "...\\n"));
            result = Boot.load_path(path);
            result.factory().file_path()._set(0, path);
          } else {
            name = path.split("/")._get(- 1).split(".")._get(0);
            name._set(name.rindex("_"), ".");
            result = Cache.load_cache(name);
          }
        } else {
          try {
            header = File.open(function(x) {
              return x.readline();
            }, path);
          } catch ( err ) {
            self.puts(S("Unable to open file ", path));
            self.raise(err);
          }
          if (header == "#ruby") {
            System.stderr().push(S("## building ", path, "...\\n"));
            str = File.read(path);
            result = self.instance_eval(str);
            result.factory().file_path()._set(0, path);
            a = str.split("\\\"").map(function(x) {
              return x.split("\\'");
            }).flatten();
            fnames = a.values_at.apply(a, [].concat( a.each_index().select(function(i) {
              return i.odd_P();
            }) ));
            fnames.each(function(fn) {
              return result.factory().file_path().push(fn);
            });
          } else {
            System.stderr().push(S("## loading ", path, "...\\n"));
            result = Parse.load_file(path, grammar, schema, encoding);
          }
        }
        return result;
      };

      this.find_model = function(block, name) {
        var self = this; 
        var path;
        if (File.exists_P(name)) {
          return block(name);
        } else {
          path = Dir._get("**/*.*").find(function(p) {
            return File.basename(p) == name;
          });
          if (path == null) {
            return null;
          } else {
            if (! path) {
              self.raise(EOFError, S("File not found ", name));
            }
            return block(path);
          }
        }
      };
    });

  Load = {
    load: function(name) {
      return Loader.load(name);
    },

    Load_text: function(type, factory, source, show) {
      if (show === undefined) show = false;
      return Load.load_text(type, factory, source, show);
    },

    LoaderClass: LoaderClass,
    Loader: LoaderClass.new(),

  };
  return Load;
})
